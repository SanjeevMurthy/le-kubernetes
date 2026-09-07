# Q36. Archive with exclusions, extract, symbolic and hard links

Everything for this task is under `/opt/course/36` (`$COURSE_DIR/36` on this lab): a `project` directory, an archive named `bundle.tar.xz`, and a file named `notes.txt`.

1. Create `/opt/course/36/project.tar.gz`, a gzip compressed tar archive of the `project` directory that contains none of its `.tmp` files.
2. Extract `bundle.tar.xz` into a new directory `/opt/course/36/extracted`, so that `/opt/course/36/extracted/v2` exists.
3. Create `/opt/course/36/current` as a symbolic link that resolves to `/opt/course/36/extracted/v2`.
4. Create `/opt/course/36/notes.hard` as a hard link to `notes.txt`, so that both names refer to one inode.

The grader lists the archive with `tar`, reads the extracted file, resolves the symbolic link with `readlink -f`, and compares inode numbers and link counts with `stat`.
