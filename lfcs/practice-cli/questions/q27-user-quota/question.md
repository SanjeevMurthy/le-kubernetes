# Q27. User quota on a filesystem

A separate filesystem is mounted at `/quota` and listed in `/etc/fstab`. It was created with no quota support at all. The user `qa` already exists.

Put a user quota on it:

- User quotas are enabled on `/quota`, now and after a reboot.
- User `qa` has a **soft limit of 51200 blocks** and a **hard limit of 102400 blocks** on `/quota`.
- `qa` has no inode limits: both inode limits stay `0`.

Nothing about quotas works until the filesystem is mounted with the right option, so start there.

The grader reads `findmnt`, `quotaon -p` and `repquota` for the live half, and `/etc/fstab` for the persistent half, and it runs `findmnt --verify`. Quotas that work now but are missing from `/etc/fstab` score nothing.
