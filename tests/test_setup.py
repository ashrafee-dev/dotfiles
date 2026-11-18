"""Safe installer regression tests. Run: python3 -m unittest discover -s tests -v"""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


class SetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles-test-")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.config = self.home / "config"
        self.state = self.home / "state"
        self.env = dict(os.environ, HOME=str(self.home),
                        ZDOTDIR=str(self.home),
                        XDG_CONFIG_HOME=str(self.config),
                        XDG_STATE_HOME=str(self.state),
                        XDG_DATA_HOME=str(self.home / "data"),
                        XDG_CACHE_HOME=str(self.home / "cache"))

    def run_script(self, script, *args):
        return subprocess.run(["sh", str(REPO / script), *args], env=self.env,
                              text=True, capture_output=True, timeout=90)

    def test_shell_syntax(self):
        for script in ("install.sh", "bootstrap.sh", "doctor.sh", "dotfiles.sh"):
            result = subprocess.run(["sh", "-n", str(REPO / script)], capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_dry_run_does_not_write(self):
        for script in ("install.sh", "bootstrap.sh"):
            result = self.run_script(script, "--dry-run")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertFalse(self.config.exists())
            self.assertFalse(self.state.exists())

    def test_backup_credentials_and_idempotency(self):
        (self.config / "nvim").mkdir(parents=True)
        (self.config / "nvim/original").write_text("keep me")
        (self.config / "gh").mkdir()
        (self.config / "gh/hosts.yml").write_text("private test fixture")
        for _ in range(2):
            result = self.run_script("install.sh")
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.config / "nvim").resolve(), REPO / ".config/nvim")
        self.assertEqual((self.config / "gh/hosts.yml").read_text(), "private test fixture")
        backups = list(self.state.glob("dotfiles/backups/*/config/nvim/original"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), "keep me")

    def test_cli_and_shell_setup_are_idempotent(self):
        rc = self.home / ".zshrc"
        rc.write_text("# existing settings\n")
        for _ in range(2):
            result = self.run_script("install.sh")
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(rc.read_text().count("# dotfiles CLI"), 1)
        self.assertTrue(rc.read_text().startswith("# existing settings\n"))
        backups = list(self.state.glob("dotfiles/backups/*/shell/.zshrc"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), "# existing settings\n")
        cli = self.home / ".local/bin/dotfiles"
        result = subprocess.run([str(cli), "help"], cwd=self.home, env=self.env,
                                text=True, capture_output=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Usage: dotfiles", result.stdout)

    def test_invalid_arguments_fail(self):
        for script in ("install.sh", "bootstrap.sh", "doctor.sh"):
            self.assertEqual(self.run_script(script, "--invalid").returncode, 2)

    def test_dotfiles_command_validation(self):
        for args in (("--invalid",), ("push",), ("push", ""), ("test", "extra")):
            self.assertEqual(self.run_script("dotfiles.sh", *args).returncode, 2)
        self.assertEqual(self.run_script("dotfiles.sh", "help").returncode, 0)

    def test_fresh_shell_discovers_command_without_existing_local_path(self):
        result = self.run_script("install.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Verified:", result.stdout)
        env = dict(self.env, PATH="/usr/bin:/bin")
        shells = []
        if shutil.which("zsh"):
            shells.append([shutil.which("zsh"), "-ic", "command -v dotfiles"])
        if shutil.which("bash"):
            shells.append([shutil.which("bash"), "--noprofile", "--rcfile",
                           str(self.home / ".bashrc"), "-ic", "command -v dotfiles"])
        for command in shells:
            result = subprocess.run(command, env=env, text=True, capture_output=True, timeout=10)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(str(self.home / ".local/bin/dotfiles"), result.stdout)

    def test_login_profile_and_custom_zdotdir_are_preserved(self):
        profile = self.home / ".bash_login"
        profile.write_text("# keep login settings\n")
        self.env["ZDOTDIR"] = str(self.home / "zsh-config")
        for _ in range(2):
            result = self.run_script("install.sh")
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.home / ".bash_profile").exists())
        self.assertFalse((self.home / ".profile").exists())
        self.assertTrue(profile.read_text().startswith("# keep login settings\n"))
        self.assertEqual(profile.read_text().count("# dotfiles CLI"), 1)
        self.assertEqual((self.home / "zsh-config/.zshrc").read_text().count("# dotfiles CLI"), 1)

    def test_push_stops_before_git_mutation_when_tests_fail(self):
        bin_dir = self.home / "bin"
        bin_dir.mkdir()
        log = self.home / "commands.log"
        for name, body in {
            "python3": "exit 7\n",
            "git": 'echo "$*" >> "$TEST_LOG"\nexit 0\n',
        }.items():
            path = bin_dir / name
            path.write_text("#!/bin/sh\n" + body)
            path.chmod(0o755)
        self.env["PATH"] = str(bin_dir) + os.pathsep + self.env["PATH"]
        self.env["TEST_LOG"] = str(log)
        result = self.run_script("dotfiles.sh", "push", "test")
        self.assertEqual(result.returncode, 7)
        self.assertEqual(log.read_text().splitlines(), [
            "diff --stat HEAD", "ls-files --others --exclude-standard",
            "diff --check", "diff --cached --check",
        ])

    def test_bootstrap_stops_on_provisioning_failure(self):
        bin_dir = self.home / "bin"
        bin_dir.mkdir()
        log = self.home / "commands.log"
        commands = {
            "brew": 'echo "brew $*" >> "$TEST_LOG"\nexit 0\n',
            "npm": 'echo "npm $*" >> "$TEST_LOG"\nexit 7\n',
            "nvim": 'echo "nvim $*" >> "$TEST_LOG"\nexit 7\n',
        }
        for name, body in commands.items():
            path = bin_dir / name
            path.write_text("#!/bin/sh\n" + body)
            path.chmod(0o755)
        self.env["PATH"] = str(bin_dir) + os.pathsep + self.env["PATH"]
        self.env["TEST_LOG"] = str(log)
        result = self.run_script("bootstrap.sh")
        self.assertEqual(result.returncode, 7, result.stdout + result.stderr)
        recorded = log.read_text()
        self.assertIn("brew bundle --file=", recorded)
        self.assertIn("npm install", recorded)
        self.assertNotIn("nvim-doctor.lua", recorded)

    @unittest.skipUnless(shutil.which("nvim"), "Neovim not installed")
    def test_doctor_rejects_unprovisioned_machine(self):
        result = self.run_script("doctor.sh")
        output = result.stdout + result.stderr
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("FAILED:", output)
        self.assertNotIn("PASSED:", output)
        self.assertFalse((self.home / "data/nvim/lazy").exists())


if __name__ == "__main__":
    unittest.main()
