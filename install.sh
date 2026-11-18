#!/bin/sh
# Link only explicitly managed configs; never replace a whole ~/.config.
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
config=${XDG_CONFIG_HOME:-"$HOME/.config"}
state=${XDG_STATE_HOME:-"$HOME/.local/state"}
backup="$state/dotfiles/backups/$(date +%Y%m%d-%H%M%S)-$$"
dry_run=false
case "${1:-}" in
  '') ;;
  --dry-run) dry_run=true ;;
  *) echo "Usage: $0 [--dry-run]" >&2; exit 2 ;;
esac

link() {
  source=$1
  target=$2
  label=$3
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    printf 'Already linked: %s\n' "$target"
    return
  fi
  printf 'Link: %s -> %s\n' "$target" "$source"
  if "$dry_run"; then return; fi
  mkdir -p "$(dirname "$target")"
  if [ -e "$target" ] || [ -L "$target" ]; then
    mkdir -p "$backup/$(dirname "$label")"
    mv "$target" "$backup/$label"
    printf 'Backup: %s\n' "$backup/$label"
  fi
  ln -s "$source" "$target"
}

link "$repo/.config/nvim" "$config/nvim" config/nvim
if ! "$dry_run"; then chmod +x "$repo/dotfiles.sh"; fi
link "$repo/dotfiles.sh" "$HOME/.local/bin/dotfiles" bin/dotfiles
# Add only an idempotent PATH line; preserve existing shell customizations.
path_line='case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac # dotfiles CLI'
# Bash login shells read the first existing profile. Do not create a new
# .bash_profile that would hide an existing .profile or .bash_login.
bash_profile=.profile
for candidate in .bash_profile .bash_login .profile; do
  if [ -f "$HOME/$candidate" ]; then bash_profile=$candidate; break; fi
done
for rc in .zshrc .bashrc "$bash_profile"; do
  if [ "$rc" = .zshrc ]; then
    target="${ZDOTDIR:-$HOME}/.zshrc"
  else
    target="$HOME/$rc"
  fi
  if [ -f "$target" ] && grep -Fqx "$path_line" "$target"; then continue; fi
  printf 'Add dotfiles CLI to PATH in %s\n' "$target"
  if "$dry_run"; then continue; fi
  mkdir -p "$(dirname "$target")"
  if [ -e "$target" ]; then
    mkdir -p "$backup/shell"
    cp -p "$target" "$backup/shell/$rc"
  fi
  printf '\n%s\n' "$path_line" >> "$target"
done
link "$repo/.config/gh/config.yml" "$config/gh/config.yml" config/gh/config.yml
for file in "$repo"/.config/fish/conf.d/*.fish; do
  name=$(basename "$file")
  link "$file" "$config/fish/conf.d/$name" "config/fish/conf.d/$name"
done

if [ "$(uname -s)" = Darwin ]; then
  link "$repo/.config/karabiner" "$config/karabiner" config/karabiner
  link "$repo/.hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua" hammerspoon/init.lua
fi

printf 'Configs linked. For development tools: sh bootstrap.sh. To check readiness: sh doctor.sh.\n'
if ! "$dry_run"; then
  "$HOME/.local/bin/dotfiles" help >/dev/null
  printf '\nVerified: %s\n' "$HOME/.local/bin/dotfiles"
  printf 'New terminals can use: dotfiles update\n'
  printf 'In this terminal, use the full path (no PATH changes needed):\n  "%s" check\n' "$HOME/.local/bin/dotfiles"
  printf 'The installer cannot change the PATH of its parent terminal.\n'
fi
