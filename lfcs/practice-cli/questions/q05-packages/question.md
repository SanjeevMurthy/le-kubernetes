# Q05. Install, hold, verify, and report packages

This host is being prepared for a service rollout. Use the package manager of whichever distribution you are on.

1. Install the `tree` package.
2. Install `nginx`, but leave it stopped and make sure it does not start at the next boot.
3. Freeze the installed `nginx` version so a later upgrade cannot move it.
4. Write the installed version of the `openssl` package to `/opt/course/5/version.txt` (`$COURSE_DIR/5/version.txt` on this lab). Write only the version string, exactly as the package manager reports it: the `${Version}` field on the Debian family, or `%{VERSION}-%{RELEASE}` on the RHEL family.
5. Verify the files of the `bash` package against the package database and write the result to `/opt/course/5/verify.txt`. An empty file is the correct answer when nothing has been modified, so create the file either way.
