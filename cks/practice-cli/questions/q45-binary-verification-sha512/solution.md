# Q45. Verify the release binaries and remove the tampered one (solution)

## Steps

Everything happens in the working directory, as an ordinary user.

```bash
cd /opt/course/45/binaries
```

**1. Let `sha512sum` do the comparison.** It reads the published list and checks every file named in it. This is the whole task in one command, and it is the command to reach for rather than hashing each file by hand and comparing 128 hex characters with your eyes.

```bash
sha512sum --check checksums.txt
```

```
kubectl: FAILED
kubeadm: OK
kubelet: OK
kube-proxy: OK
sha512sum: WARNING: 1 computed checksum did NOT match
```

The `FAILED` line names the file. Add `--quiet` to print only the failures, which is easier to read when the list is long:

```bash
sha512sum --check --quiet checksums.txt
```

**2. Write the deliverable.** The task asked for the file name alone, so do not pipe the whole `FAILED` line into it.

```bash
sha512sum --check --quiet checksums.txt 2>/dev/null \
  | awk -F: '/FAILED/ {print $1}' > /opt/course/45/tampered
cat /opt/course/45/tampered
```

**3. Delete the tampered binary, and nothing else.**

```bash
rm -f "/opt/course/45/binaries/$(cat /opt/course/45/tampered)"
```

**4. Confirm.** Re-running the check now reports the deleted file as missing rather than as a mismatch, and every remaining file passes. Both halves matter: a missing file is the expected state, and any remaining `FAILED` means you deleted the wrong one.

```bash
sha512sum --check checksums.txt
```

```
sha512sum: kubectl: No such file or directory
kubectl: FAILED open or read
kubeadm: OK
kubelet: OK
kube-proxy: OK
sha512sum: WARNING: 1 listed file could not be read
```

## Doing it by hand

If the list is not in `sha512sum`'s own format, or you are checking a single binary against a hash pasted from a release page, compare them directly:

```bash
sha512sum kubectl
echo "<hash-from-the-release-page>  kubectl" | sha512sum --check -
```

The two spaces between the hash and the file name are part of the format. One space makes `sha512sum --check` reject the line as improperly formatted, which reads like a checksum failure and is not one.

## Why

An attacker who can replace a binary on a node owns the node, and from the kubelet or kubeadm they own rather more than that. The published checksum is the only thing standing between a mirror you do not control and a control plane you do. The exam bullet is "verify platform binaries before deploying", and the task is always the same shape: some binaries, some published hashes, find the one that lies.

Checking the hash of a binary that is already running is the same idea applied to a process rather than a file:

```bash
sha512sum /usr/bin/kubelet
sha512sum /proc/$(pidof kubelet)/exe
```

`/proc/<pid>/exe` is the image the process was actually started from. If it disagrees with the file on disk, the file was replaced after the service started, and restarting the service is what would arm it.

## Gotchas

- `sha512sum --check` needs to run in the directory the file names in the list are relative to, or it reports every file as missing. `cd` first.
- Do not regenerate `checksums.txt`. Running `sha512sum * > checksums.txt` makes every file match, destroys the evidence, and is the one action that turns a passing answer into a failing one.
- `sha256sum` and `sha512sum` are different commands. Read which one the list is: a SHA256 hash is 64 hex characters, a SHA512 is 128.
- The exit status is the machine-readable answer. `sha512sum --check --status checksums.txt` prints nothing and exits non-zero on any mismatch, which is what to use inside a script.
- On macOS the command is `shasum -a 512`. The exam hosts are Linux, so `sha512sum` is the one to have in your fingers.

## Docs

The CKS exam allows `kubernetes.io/docs`, which covers the release-verification pages, and every host has `man`.

- `man 1 sha512sum`, in particular the `--check`, `--quiet` and `--status` flags
- https://kubernetes.io/releases/ for where published checksums live
