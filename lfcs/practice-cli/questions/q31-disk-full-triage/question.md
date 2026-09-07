# Q31. Filesystem nearly full: recover space and find the hidden consumer

The filesystem mounted at `/srv/data` is over 80 percent full and an application on it is about to start failing writes.

Bring it back under control:

- Get `/srv/data` under **60 percent** used.
- Everything under `/srv/data/tmp` is scratch and can be deleted.
- Nothing under `/srv/data/archive` may be deleted. Those files are the point of the filesystem.
- Write the full path of the single largest **remaining** file on `/srv/data` into `/opt/course/31/biggest.txt`, on one line and nothing else.
- Leave `/srv/data` mounted, and leave its `/etc/fstab` line working.

Deleting the scratch directory alone will not get you under 60 percent. Some of the space is held by something `du` cannot see.

The grader reads `df`, scans `/proc` for processes holding deleted files on `/srv/data`, reads your answer file, and reads `/etc/fstab`. It also runs `findmnt --verify`.
