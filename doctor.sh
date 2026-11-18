#!/bin/sh
# Read-only checks: never install packages or collect credentials.
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
if [ "$#" -ne 0 ]; then echo 'Usage: sh doctor.sh' >&2; exit 2; fi
if ! command -v nvim >/dev/null 2>&1; then
  echo 'FAILED: Neovim is missing. Run sh bootstrap.sh.' >&2
  exit 1
fi
export DOTFILES_REPO="$repo"
exec nvim --headless -l "$repo/scripts/nvim-doctor.lua"
