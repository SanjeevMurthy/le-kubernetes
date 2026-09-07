#!/bin/bash
# Q32 git: build a bare repository holding one commit on main, and clear away any
# previous clone so the task starts from a clone that has not been made yet.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

DIR=$(course_dir 32)
BARE="$DIR/repo.git"
WORK="$DIR/work"
SEED="$DIR/seed"

command -v git >/dev/null 2>&1 || pkg_install git
if ! has_needs "tool:git"; then
  echo "git is still missing. Install the git package and run setup again."
  exit 1
fi

rm -rf "$BARE" "$WORK" "$SEED"

git init -q --bare --initial-branch=main "$BARE" 2>/dev/null || git init -q --bare "$BARE"

git init -q "$SEED"
git -C "$SEED" symbolic-ref HEAD refs/heads/main
mkdir -p "$SEED/src"
echo "lab application" > "$SEED/README.md"
echo 'print("hello")' > "$SEED/src/app.py"
git -C "$SEED" add -A
git -C "$SEED" -c user.name='Lab Seed' -c user.email='seed@lab.local' \
  commit -q -m 'Initial commit'
git -C "$SEED" push -q "$BARE" main
rm -rf "$SEED"

CURRENT=$(git config --get user.email 2>/dev/null)

echo "Setup complete."
echo "  Bare repository: $BARE (one commit on main)"
echo "  No clone exists yet at $WORK"
if [[ -n "$CURRENT" ]]; then
  echo "  The git identity visible here is currently $CURRENT, which is not the one the task wants."
else
  echo "  No git identity is configured here yet."
fi
echo "  Branch to create and push: feature/lfcs"
echo "  Commit author email required: lfcs@example.com"
