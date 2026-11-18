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
                        XDG_CONFIG_HOME=str(self.config),
                        XDG_STATE_HOME=str(self.state),
                        XDG_DATA_HOME=str(self.home / "data"),
                        XDG_CACHE_HOME=str(self.home / "cache"))

    def run_script(self, script, *args):
        return subprocess.run(["sh", str(REPO / script), *args], env=self.env,
                              text=True, capture_output=True, timeout=90)

    def test_shell_syntax(self):
        for script in ("install.sh", "bootstrap.sh", "doctor.sh"):
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

    def test_invalid_arguments_fail(self):
        for script in ("install.sh", "bootstrap.sh", "doctor.sh"):
            self.assertEqual(self.run_script(script, "--invalid").returncode, 2)

    def test_bootstrap_stops_on_provisioning_failure(self):
        bin_dir = self.home / "bin"
        bin_dir.mkdir()
        log = self.home / "commands.log"
        commands = {
            "brew": 'echo "brew $*" >> "$TEST_LOG"\nexit 0\n',
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
        self.assertIn("nvim-setup.lua", recorded)
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
