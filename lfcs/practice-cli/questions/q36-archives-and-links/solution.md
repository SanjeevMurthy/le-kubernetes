# Q36. Archive with exclusions, extract, symbolic and hard links (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. Build the gzip archive without the temporary files.**

```bash
cd /opt/course/36
tar czf project.tar.gz --exclude='*.tmp' project
tar tzf project.tar.gz
```

**2. Extract the xz archive into a new directory.**

```bash
mkdir -p /opt/course/36/extracted
tar tJf bundle.tar.xz                       # list before extracting
tar xJf bundle.tar.xz -C /opt/course/36/extracted
ls /opt/course/36/extracted/v2
```

**3. Point a symbolic link at the extracted directory.**

```bash
ln -s /opt/course/36/extracted/v2 /opt/course/36/current
readlink -f /opt/course/36/current
```

**4. Add a hard link to the notes file.**

```bash
ln /opt/course/36/notes.txt /opt/course/36/notes.hard
stat -c '%i %h %n' /opt/course/36/notes.txt /opt/course/36/notes.hard
```

## Why

The tar flags are a small alphabet: `c` create, `x` extract, `t` list, `f` the archive file, `z` gzip, `j` bzip2, `J` xz, `v` verbose, `p` preserve permissions. Tar picks the compressor from the flag and not from the file name, so `tar czf x.tar.xz` quietly writes gzip data under a misleading name. GNU tar also accepts `-a` to choose from the suffix.

`--exclude` takes a shell pattern and must be quoted, otherwise the shell expands `*.tmp` against the current directory before tar ever sees it. Listing the finished archive with `tar tzf` is the only proof the exclusion worked.

Extraction needs `-C` because tar strips the leading slash and unpacks relative to the working directory. Extracting as root with `-p` keeps the stored permissions.

A symbolic link stores a path. It can cross filesystems, can point at a directory, and breaks silently when its target moves, so an absolute target is the safer choice. A hard link is a second directory entry for one inode: it cannot cross a filesystem, cannot point at a directory, and the file's data survives until the last name is removed. Identical inode numbers and a link count of 2 are what prove a hard link; `ls -l` shows the count in the second column.

## Verify

```bash
cd /opt/course/36
file project.tar.gz                       # gzip compressed data
tar tzf project.tar.gz | grep -c '\.tmp$' # expect 0
cat extracted/v2/VERSION

test -L current && readlink -f current    # /opt/course/36/extracted/v2
stat -c '%i %h %n' notes.txt notes.hard   # same inode, link count 2
```

## Docs

- `man 1 tar` for the operation letters, `--exclude` and `-C`
- `man 1 gzip`, `man 1 xz` and `man 1 zip` for the standalone compressors
- `man 1 ln` for `-s` and for the hard link rules
- `man 1 readlink` for `-f`
- `man 1 stat` for `%i` and `%h`
- `man 7 symlink` for how the kernel resolves a symbolic link
