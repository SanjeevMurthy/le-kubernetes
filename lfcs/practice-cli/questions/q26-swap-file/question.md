# Q26. Add a swap file with a priority, persistent

This host needs more swap, and it has no spare partition to give it.

Add swap backed by a file:

- The file is `/swapfile2` and it is **512 MB**.
- Its permissions are `600` and it is owned by root.
- It is in use as swap now, at **priority 10**.
- It comes back as swap, still at priority 10, after a reboot.

Leave the existing swap alone.

The grader reads `swapon --show`, `/proc/swaps`, `stat` and `/etc/fstab`, and runs `findmnt --verify`. Swap that is active but absent from `/etc/fstab` scores nothing, and so does an fstab line without the priority.
