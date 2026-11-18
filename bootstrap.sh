#!/bin/sh
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
case "${1:-}" in
  --dry-run)
    printf 'Would install Brewfile dependencies, link configs, install tsx and Chromium,\nrestore Neovim plugins, install language/debug tools and parsers, then run doctor.\n'
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
export JAVA_HOME="$(brew --prefix openjdk@21)/libexec/openjdk.jdk/Contents/Home"
if [ ! -d "$JAVA_HOME" ]; then JAVA_HOME="$(brew --prefix openjdk@21)/libexec"; export JAVA_HOME; fi
export DOTFILES_LLVM_BIN="$(brew --prefix llvm)/bin"
export PATH="$JAVA_HOME/bin:$DOTFILES_LLVM_BIN:$PATH"
debug_home="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/dotfiles-debug"
mkdir -p "$debug_home"
npm install --prefix "$debug_home" --no-audit --no-fund playwright@1.58.2 tsx@4.21.0
"$debug_home/node_modules/.bin/playwright" install chromium
export DOTFILES_DEBUG_HOME="$debug_home"
node "$repo/scripts/debug-environment.cjs"
export DOTFILES_REPO="$repo"
nvim --headless -l "$repo/scripts/nvim-setup.lua"
exec sh "$repo/doctor.sh"
