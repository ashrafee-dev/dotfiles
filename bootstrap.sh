#!/bin/sh
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
case "${1:-}" in
  --dry-run)
    printf 'Would install Brewfile dependencies, link configs, restore Neovim plugins,\ninstall language/debug tools and parsers, then run doctor.\n'
    exec sh "$repo/install.sh" --dry-run ;;
  '') ;;
  *) echo "Usage: sh bootstrap.sh [--dry-run]" >&2; exit 2 ;;
esac
case "$(uname -s)" in
  Darwin|Linux) ;;
  *) echo 'Unsupported OS. Use macOS, Linux, or WSL.' >&2; exit 1 ;;
esac
# Find a previously installed Homebrew even in a fresh login shell.
if ! command -v brew >/dev/null 2>&1; then
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [ -x "$candidate" ]; then eval "$("$candidate" shellenv)"; break; fi
  done
fi
if ! command -v brew >/dev/null 2>&1; then
  echo 'Install Homebrew first using the official instructions: https://brew.sh' >&2
  echo 'Then rerun sh bootstrap.sh. No remote installer is executed automatically.' >&2
  exit 1
fi
eval "$(brew shellenv)"
if ! command -v cc >/dev/null 2>&1 || ! command -v make >/dev/null 2>&1; then
  echo 'A C compiler and make are required. On macOS: xcode-select --install.' >&2
  echo 'On Debian/Ubuntu: sudo apt install build-essential.' >&2
  exit 1
fi
brew bundle --file="$repo/Brewfile"
sh "$repo/install.sh"
export DOTFILES_REPO="$repo"
nvim --headless -l "$repo/scripts/nvim-setup.lua"
exec sh "$repo/doctor.sh"
