# Dotfiles

For language-specific launch profiles and debugger shortcuts, see
[Debugging](docs/debugging.md). Bootstrap provisions Python, C/C++, Go, Java,
JavaScript/TypeScript, and Chromium-based React debugging tools.

Shared configuration for macOS and Linux. Keep this repository at `~/dotfiles`;
the installer symlinks explicitly managed settings into your home directory.
Existing settings are backed up, not deleted. No sudo is needed.

## First setup on each device

Install Git and configure GitHub SSH access, then:

```sh
git clone git@github.com:ashrafee-dev/dotfiles.git ~/dotfiles
cd ~/dotfiles
sh install.sh --dry-run
sh install.sh
```

## Full development setup (recommended)

For a new machine, install Homebrew from <https://brew.sh> first (macOS or
Linux/WSL). Its platform prerequisites include Command Line Tools on macOS
(`xcode-select --install`) or a C compiler and `make` on Linux. Then run:

```sh
cd ~/dotfiles
sh bootstrap.sh --dry-run
sh bootstrap.sh
```

Unlike the lightweight `install.sh`, **bootstrap installs software** using the
committed `Brewfile`, links configs, restores the locked Neovim plugins, waits
for Mason to install language servers/formatters/linters/debug adapters, installs
Treesitter parsers, and runs the checks below. It needs network access and may
take several minutes. Package-manager downloads/builds can fail; rerun after
fixing the reported error. No manual `:Lazy` or `:Mason` install is intended.

Included development tools cover Go (`gopls`, Delve, goimports, gofumpt,
golangci-lint), Lua, JSON, Markdown, and Python/JavaScript debug adapters.
Python and Node runtimes are installed too. Adding another language or tool
requires updating the shared manifest in `.config/nvim/lua/config/tools.lua`
and the corresponding editor configuration. Homebrew/Mason tools use available
releases, while Neovim plugins use `lazy-lock.json`; this is repeatable setup,
not a bit-for-bit frozen system image.

```sh
sh doctor.sh
```

Doctor checks links, required executable availability, core plugin directories,
Mason tool installation, parser loading, and runs smoke tests for Go/Node,
Delve, gopls, golangci-lint, and Python's debug adapter. It exits nonzero on a
required failure and only prints **PASSED** when all required checks succeed.
It does not install packages or ask for credentials. GitHub authentication is an
optional warning; use `gh auth login` through the official flow if needed.

**Still device/project-specific:** GitHub SSH access, other credentials,
Hammerspoon/Karabiner GUI installation and macOS permissions, terminal font
selection, Linux browser system libraries when missing, and project dependencies
(`go mod download`, `npm install`, Python virtual environments). Doctor does not
claim to test those or run live debug sessions. Projects must also provide a
golangci-lint configuration compatible with the installed version.

Install the applications you use separately: a current Neovim supported by
LazyVim, GitHub CLI, and optionally Fish. Neovim installs its plugins on first
launch using the committed `lazy-lock.json`. Language servers, language
runtimes, Nerd Fonts, and external tools may require separate installation.
On macOS, install Karabiner-Elements and Hammerspoon and grant their required
permissions. These two configs are automatically skipped on Linux.
Windows users need WSL for the Unix setup; native Windows is not supported.

## Keep devices in sync

```sh
cd ~/dotfiles
git pull --ff-only
sh bootstrap.sh
```

Existing links reflect pulled changes immediately; rerunning the idempotent
installer also handles newly added mappings. Restart/reload affected apps.
Use `sh install.sh` instead when you only want to update links without installing
or restoring development tools.
Before switching devices, commit and push any intentional config edits:

```sh
cd ~/dotfiles
git status
git add <files-you-changed>
git commit -m "Update configuration"
git push
```

Review changes before committing: apps can write settings through symlinks.
Do not force-push to resolve divergent device edits.

## What is managed

- `.config/nvim/`: current Neovim config, excluding the accidental nested repo
  and local API-key file.
- `.config/gh/config.yml`: CLI preferences only; run `gh auth login` per device.
- `.config/fish/conf.d/`: optional integrations, guarded when tools are absent.
- `.config/karabiner/` and `.hammerspoon/init.lua`: macOS settings.
- `.zshrc`: retained from the original repository, **not installed** because it
  depends on a separate Oh My Zsh/Powerlevel10k setup and a machine-local path.

Credentials, app login state, caches, dependencies, Karabiner backups, and
generated environment-manager paths are intentionally not synced. Keep secrets
in a password manager or local environment, not this repository. SSH keys and
application installations are also per-device.

`XDG_CONFIG_HOME` and `XDG_STATE_HOME` are respected. Replaced files are stored
under `${XDG_STATE_HOME:-~/.local/state}/dotfiles/backups/` in a timestamped
directory. To undo a link, remove only that symlink and move the corresponding
backup into its original location. Backups may contain private files; never
commit them. Keep the repository in place while its symlinks are in use.
