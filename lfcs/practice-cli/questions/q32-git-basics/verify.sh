#!/bin/bash
# Q32 git: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

BARE="$COURSE_DIR/32/repo.git"
WORK="$COURSE_DIR/32/work"

echo "Checking the clone..."
check "a working clone exists at $WORK" test -d "$WORK/.git"
check_contains "the clone's origin is repo.git" "repo.git" \
  "$(git -C "$WORK" config --get remote.origin.url 2>/dev/null)"
check_eq "the checked out branch is feature/lfcs" "feature/lfcs" \
  "$(git -C "$WORK" rev-parse --abbrev-ref HEAD 2>/dev/null)"

echo "Checking the ignore rule..."
check_file_has ".gitignore holds the *.log pattern" '^[[:space:]]*\*\.log[[:space:]]*$' "$WORK/.gitignore"
check "git ignores a file named run.log" git -C "$WORK" check-ignore -q run.log
# The control case above proves check-ignore runs and reports a match here, so a
# non-zero exit below really means "not ignored" and not "the command is broken".
check_not "git does not ignore a file named run.txt" git -C "$WORK" check-ignore -q run.txt
check ".gitignore is tracked, not merely present" git -C "$WORK" ls-files --error-unmatch .gitignore

echo "Checking the commit..."
check_eq "the last commit is authored by lfcs@example.com" "lfcs@example.com" \
  "$(git -C "$WORK" log -1 --format='%ae' 2>/dev/null)"
check_contains "the last commit is on feature/lfcs" "feature/lfcs" \
  "$(git -C "$WORK" branch --contains HEAD 2>/dev/null)"

echo "Checking the branch reached the shared repository..."
check "repo.git carries a feature/lfcs branch" \
  git --git-dir="$BARE" rev-parse --verify --quiet refs/heads/feature/lfcs
check_contains "the pushed branch carries the ignore rule" "*.log" \
  "$(git --git-dir="$BARE" show feature/lfcs:.gitignore 2>/dev/null)"

echo "Checking the identity is stored and not typed once..."
check_persisted "user.email is recorded in a git configuration file" \
  'lfcs@example\.com' \
  "$WORK/.git/config" /root/.gitconfig "$HOME/.gitconfig" /etc/gitconfig

summary
