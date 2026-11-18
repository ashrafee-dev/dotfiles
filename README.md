# Dotfiles

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
sh install.sh
```

Existing links reflect pulled changes immediately; rerunning the idempotent
installer also handles newly added mappings. Restart/reload affected apps.
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
