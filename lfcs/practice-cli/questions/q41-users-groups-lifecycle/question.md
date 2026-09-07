# Q41. Create users with exact attributes, a system account, and lock one

Three account tasks on this host. Every attribute below is graded on its own line, so a nearly correct account still loses the parts that are wrong.

1. Create the group `devs` with GID `3001` and the group `qa` with GID `3002`.
2. Create the user `ana` with all of these attributes:
   - UID `2001`
   - primary group `devs`
   - supplementary group `qa`
   - login shell `/bin/bash`
   - home directory `/home/ana`, created and owned by her
   - comment field `Ana Diaz`
   - account expiry date `2027-06-30`
   Then set her password to `Lfcs2026Pass`, because an account with no password cannot log in at all.
3. Create the system account `svc-batch`: a UID below 1000 and a shell that refuses logins. It needs no home directory.
4. The account `bob` already exists. Lock his password so he cannot log in, without deleting the account and without changing his shell.

The grader reads `getent passwd`, `getent group`, `id`, `ls -ld`, `chage -l` and `passwd -S`, one attribute at a time.
