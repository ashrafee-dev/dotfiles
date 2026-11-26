#!/bin/sh
# Run from any directory: sh ~/dotfiles/dotfiles.sh <command>
set -eu
script=$0
while [ -L "$script" ]; do
  directory=$(CDPATH= cd -- "$(dirname -- "$script")" && pwd -P)
  target=$(readlink "$script")
  case "$target" in
    /*) script=$target ;;
    *) script=$directory/$target ;;
  esac
done
repo=$(CDPATH= cd -- "$(dirname -- "$script")" && pwd -P)
cd "$repo"
command=${1:-help}
if [ "$#" -gt 0 ]; then shift; fi
usage() {
  echo 'Usage: dotfiles setup|update|test|check|status'
  echo '       dotfiles push "Commit message"'
}
test_repo() {
  git diff --check
  git diff --cached --check
  python3 -m unittest discover -s tests -v
  DOTFILES_REPO="$repo" nvim --clean --headless -l tests/debug-config.lua
}
case "$command" in
  setup|update|test|check|status)
    if [ "$#" -ne 0 ]; then usage >&2; exit 2; fi ;;
  push)
    if [ "$#" -ne 1 ] || [ -z "$1" ]; then usage >&2; exit 2; fi ;;
  help)
    usage; exit 0 ;;
  *)
    usage >&2; exit 2 ;;
esac
case "$command" in
  setup)
    sh "$repo/bootstrap.sh"
    test_repo ;;
  update)
    if [ -n "$(git status --porcelain)" ]; then
      echo 'Save your local changes with push before updating.' >&2
      exit 1
    fi
    git pull --ff-only
    sh "$repo/bootstrap.sh"
    test_repo ;;
  test)
    test_repo ;;
  check)
    exec sh "$repo/doctor.sh" ;;
  status)
    git status --short ;;
  push)
    echo 'Tracked edits and staged new files to publish:'
    git diff --stat HEAD
    echo 'Other new files (use git add to include them):'
    git ls-files --others --exclude-standard
    test_repo
    # Include tracked edits; add new files explicitly with git add first.
    git add -u
    if ! git diff --cached --quiet; then
      git commit -m "$1"
    fi
    git push ;;
esac
