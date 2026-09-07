# Q14. Hostname, hosts file, DNS servers and search domain (solution)

## Steps

**1. Set the hostname.**

```bash
hostnamectl set-hostname node1.lab.local
hostnamectl status
```

That writes `/etc/hostname`, so it is persistent already. Fix the loopback alias in `/etc/hosts` at the same time, or `sudo` prints a "unable to resolve host" warning on every call:

```bash
vim /etc/hosts
```

```
127.0.0.1   localhost
127.0.1.1   node1.lab.local node1
```

**2. Add the static host entry.**

```bash
printf '192.168.56.90\tnode9.lab.local node9\n' >> /etc/hosts
getent hosts node9
```

`/etc/hosts` is itself the persistent form, so there is no second file to write.

**3a. Ubuntu: put the resolver in the netplan file that owns the interface.**

```bash
grep -l enp0s8 /etc/netplan/*.yaml
vim /etc/netplan/50-cloud-init.yaml
```

```yaml
network:
  version: 2
  ethernets:
    enp0s8:
      dhcp4: false
      addresses:
        - 192.168.56.10/24
      nameservers:
        addresses: [1.1.1.1, 9.9.9.9]
        search: [lab.local]
```

```bash
chmod 600 /etc/netplan/50-cloud-init.yaml
netplan try
resolvectl status
```

**3b. Rocky: put the resolver on the connection.**

```bash
nmcli -t -f NAME,DEVICE con show --active
nmcli con mod "System enp0s8" ipv4.dns "1.1.1.1 9.9.9.9" ipv4.dns-search lab.local
nmcli con mod "System enp0s8" ipv4.ignore-auto-dns yes
nmcli con up "System enp0s8"
cat /etc/resolv.conf
```

`/etc/systemd/resolved.conf` with `DNS=1.1.1.1 9.9.9.9` and `Domains=lab.local` is an accepted answer on a host where `systemd-resolved` is the resolver, followed by `systemctl restart systemd-resolved`.

**4. Prove it end to end.**

```bash
hostnamectl --static
getent hosts node9
getent hosts node9.lab.local
resolvectl dns; resolvectl domain
```

## Why

Three different mechanisms hide behind the word "name" here, and the exam tends to touch all three in one task.

`hostname node1` changes the name in the running kernel and nothing else. `hostnamectl set-hostname node1.lab.local` sets the same kernel value and writes `/etc/hostname`, which is what makes it survive a reboot. There are three hostnames in systemd terms, static, transient and pretty, and `hostnamectl --static` is the one a grader reads.

`/etc/hosts` is consulted before DNS because `/etc/nsswitch.conf` lists `files` before `dns` on the `hosts` line. That is why `getent hosts node9` is the honest test and `dig node9` is not: `dig` talks to a DNS server directly and never looks at the hosts file, so it can report failure for a name every application on the host resolves perfectly.

The resolver is the part that catches people. On Ubuntu, `systemd-resolved` owns resolution, `/etc/resolv.conf` is a symlink to a stub file in `/run` that only ever contains `127.0.0.53`, and the real servers are per-link settings that `resolvectl dns` prints. Writing servers into `/etc/resolv.conf` on that host changes nothing and is undone at the next boot. On Rocky, NetworkManager writes `/etc/resolv.conf` from the connection profile, so a hand edit survives until the next `nmcli con up` and no longer. In both cases the durable place is the network configuration, which is why netplan and nmcli both have a nameserver setting.

The search domain matters more than it looks. A search list of `lab.local` is what turns `ssh node9` into a lookup for `node9.lab.local`. Changing the resolver on a host is also a good way to break later tasks that reach peers by name, so it is worth testing `getent hosts <peer>` before leaving the host.

## Verify

```bash
hostnamectl --static                    # node1.lab.local
cat /etc/hostname                       # the persistent copy
getent hosts node9                      # 192.168.56.90
resolvectl dns; resolvectl domain       # live servers and search list
grep -R -A3 nameservers /etc/netplan/   # Ubuntu persistence
nmcli -g ipv4.dns,ipv4.dns-search con show "System enp0s8"   # Rocky persistence
ls -l /etc/resolv.conf                  # normally a symlink, do not edit it
```

## Docs

- `man 1 hostnamectl` and `man 5 hostname` for the static hostname and its file
- `man 5 hosts` for the static entry format and `man 5 nsswitch.conf` for the lookup order
- `man 1 resolvectl` and `man 5 resolved.conf` for `DNS=`, `Domains=` and the stub resolver
- `man 5 netplan` for the `nameservers:` block
- `man 5 nm-settings-nmcli` for `ipv4.dns`, `ipv4.dns-search` and `ipv4.ignore-auto-dns`
