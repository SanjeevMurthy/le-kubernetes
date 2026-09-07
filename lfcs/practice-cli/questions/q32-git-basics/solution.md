# Q32. Clone, branch, ignore, commit, push (solution)

## Steps

**1. Clone the repository.**

```bash
git clone /opt/course/32/repo.git /opt/course/32/work
cd /opt/course/32/work
```

**2. Set the identity before making any commit.**

```bash
git config --global user.name "LFCS Candidate"
git config --global user.email "lfcs@example.com"
```

`--local` writes `.git/config` inside this repository only, and is equally acceptable here:

```bash
git config user.name "LFCS Candidate"
git config user.email "lfcs@example.com"
```

**3. Create and switch to the branch.**

```bash
git checkout -b feature/lfcs
git switch -c feature/lfcs      # the same thing in newer syntax
```

**4. Write the ignore rule and commit it.**

```bash
printf '*.log\n' > .gitignore
git add .gitignore
git status
git commit -m "Ignore log files"
```

**5. Push the branch and record the upstream.**

```bash
git push -u origin feature/lfcs
```

## Why

Git refuses to create a commit until it knows who is making it. Without `user.name` and `user.email` it prints "Please tell me who you are" and writes nothing, which is the usual way this task stalls. Set the identity first, as the account that must own the commit, because running the commit through `sudo` records root instead.

`--global` writes `~/.gitconfig` and follows the account into every repository. `--local` writes `.git/config` in one repository. Either counts as recording the identity; `git -c user.email=... commit` does not, because it applies to one command and leaves nothing behind.

A `.gitignore` only stops untracked files from being staged. It never removes a file that git already tracks, so a file added by mistake needs `git rm --cached <file>` as well. The `.gitignore` itself must be added and committed, since it is an ordinary tracked file.

`git push -u origin feature/lfcs` creates the branch in the bare repository and records the upstream, so a later bare `git push` from that branch works. A bare repository has no working tree, which is why it is the right shape for a shared repository and why `git --git-dir=repo.git` is the way to inspect it.

## Verify

```bash
git -C /opt/course/32/work rev-parse --abbrev-ref HEAD       # feature/lfcs
git -C /opt/course/32/work log -1 --format='%h %an <%ae> %s'
git -C /opt/course/32/work check-ignore -v run.log           # the rule that matches
git -C /opt/course/32/work ls-files .gitignore               # tracked, not just present
git --git-dir=/opt/course/32/repo.git branch --list 'feature/*'
git --git-dir=/opt/course/32/repo.git show feature/lfcs:.gitignore
git config --get user.email
```

## Docs

- `man 1 git` for the command list, and `git help -a` for every subcommand offline
- `man 1 git-config` for `user.name`, `user.email` and the difference between `--global` and `--local`
- `man 1 git-clone`, `man 1 git-checkout`, `man 1 git-switch`, `man 1 git-commit`, `man 1 git-push`
- `man 5 gitignore` for the pattern syntax, and `man 1 git-check-ignore` for proving which rule matched
