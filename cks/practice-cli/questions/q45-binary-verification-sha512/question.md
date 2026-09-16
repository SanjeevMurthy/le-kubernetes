# Q45. Verify the release binaries and remove the tampered one

**Host:** any Linux host. Work in `/opt/course/45/` (or `$COURSE_DIR/45/` on this lab).

A set of Kubernetes binaries was copied onto this host from an untrusted mirror. The checksum list that came with the official release is next to them.

`/opt/course/45/binaries/` holds four files and `checksums.txt`. Each line of `checksums.txt` is the published SHA512 of one binary, in the format `sha512sum` itself prints.

1. Check every binary in `binaries/` against its published checksum. Exactly one does not match.

2. Write the **file name only** of the binary that does not match to `/opt/course/45/tampered`. No path, no hash, nothing else on the line.

3. Delete the tampered binary from `binaries/`.

Leave the three binaries that do match exactly as they are. Do not regenerate `checksums.txt`, and do not edit it: it is the published record and the whole point of the check.
