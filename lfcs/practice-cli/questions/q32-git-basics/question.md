# Q32. Clone, branch, ignore, commit, push

A shared bare repository sits at `/opt/course/32/repo.git` (`$COURSE_DIR/32/repo.git` on this lab). It holds one commit on `main`.

1. Clone it to `/opt/course/32/work`.
2. Record the commit identity `LFCS Candidate <lfcs@example.com>` in a git configuration file, so the identity is stored rather than typed once for a single command.
3. Create the branch `feature/lfcs` and switch to it.
4. Add a `.gitignore` at the top of the working tree that ignores every file whose name ends in `.log`, and nothing else.
5. Commit the `.gitignore` on `feature/lfcs`.
6. Push the branch so that `feature/lfcs` also exists inside `repo.git`.

The grader reads `git rev-parse`, `git log`, `git check-ignore`, `git ls-files`, the branch as it exists inside `repo.git`, and the git configuration file that carries the email address.
