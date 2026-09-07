# Q01. Kernel parameters now and after reboot (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. Set both values in the running kernel.**

```bash
sysctl -w net.ipv4.ip_forward=1
sysctl -w vm.swappiness=10
```

**2. Write the same two values to a drop-in file so they come back after a reboot.**

```bash
cat >/etc/sysctl.d/90-lab.conf <<'EOF'
net.ipv4.ip_forward = 1
vm.swappiness = 10
EOF
```

**3. Apply every drop-in, which also proves the new file parses.**

```bash
sysctl --system
```

Step 3 makes step 1 unnecessary, so the fast form of the whole task is: write the file, then run `sysctl --system`.

## Why

`sysctl -w` and a write to `/proc/sys/...` change the running kernel only. Nothing on disk records them, so the next boot starts from the distribution defaults again. This is the single most common way to lose marks on this exam: the value is right when the grader looks at `sysctl -n`, and wrong the moment the host restarts.

The persistent half is a file. `/etc/sysctl.conf` still works, and the drop-in directories `/etc/sysctl.d/`, `/run/sysctl.d/` and `/usr/lib/sysctl.d/` are read in lexical order by filename, with `/etc/sysctl.conf` read last. A file named `90-lab.conf` therefore beats a vendor file named `10-network-security.conf`, which matters when the vendor file sets the same key to a different value.

`sysctl --system` reads all of those files in order and prints each one as it applies it. That printout is the fastest proof that the new file is being picked up at all, which is worth more than assuming it.

## Verify

```bash
sysctl -n net.ipv4.ip_forward      # 1
sysctl -n vm.swappiness            # 10
cat /proc/sys/net/ipv4/ip_forward  # 1

grep -RH 'ip_forward\|swappiness' /etc/sysctl.conf /etc/sysctl.d/
sysctl --system 2>&1 | grep 90-lab.conf
```

## Docs

- `man 8 sysctl` for the command, including `-w`, `-a`, `-p` and `--system`
- `man 5 sysctl.conf` for the file format
- `man 5 sysctl.d` for the drop-in directories and their read order
- `man 5 proc` for what individual keys under `/proc/sys` mean
