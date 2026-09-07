# Q12. Static IPv4 on the second NIC, persistent (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. Find the interface and see what it already has.**

```bash
ip -br addr
ip -o route show default | awk '{print $5}'    # the NIC to leave alone
ip -j addr show enp0s8                         # the lab NIC, machine readable
```

Write down every address already on that interface. One of them is probably the address your session is running over.

**2a. Ubuntu: add the address to the existing netplan file.**

Find the file that already configures the interface, and edit that file rather than adding a new one:

```bash
grep -l enp0s8 /etc/netplan/*.yaml
netplan get                                    # the merged configuration, all files together
vim /etc/netplan/50-cloud-init.yaml
```

The interface block ends up with both addresses in one list:

```yaml
network:
  version: 2
  ethernets:
    enp0s8:
      dhcp4: false
      addresses:
        - 192.168.56.10/24
        - 10.50.0.10/24
```

Two-space indent, no tab characters anywhere, and the file must be mode 600:

```bash
chmod 600 /etc/netplan/50-cloud-init.yaml
netplan try                                    # reverts by itself after 120 seconds
```

Press Enter to keep the change once the session is still alive. `netplan apply` does the same thing without the safety net.

**2b. Rocky: append the address to the connection.**

```bash
nmcli -t -f NAME,DEVICE con show --active
nmcli -g ipv4.method con show "System enp0s8"      # auto or manual, and it stays as it is
nmcli con mod "System enp0s8" +ipv4.addresses 10.50.0.20/24
nmcli con up "System enp0s8"
```

The `+` is the whole point. `nmcli con mod <con> ipv4.addresses 10.50.0.20/24` without it throws the existing address away.

Do not add `ipv4.method manual` here. This task adds an address and keeps the ones already on the interface, and on a connection that is holding a DHCP lease `manual` ends the lease, so the address the interface came up with disappears at the next `nmcli con up`. Under `auto` the addresses in `ipv4.addresses` are applied as well as the lease, which is exactly what is wanted. `manual` is right when the interface has no lease to lose, which is the case in a question that replaces DHCP with a fixed address. The one method that would fail here is `disabled`, since then nothing in `ipv4.addresses` is applied at all.

**3. Confirm both halves.**

```bash
ip -j addr show enp0s8 | grep -o '"local":"[0-9.]*"'
ip -j route show dev enp0s8
grep -n '10.50.0' /etc/netplan/*.yaml                                  # Ubuntu
nmcli -g ipv4.addresses con show "System enp0s8"                       # Rocky
```

## Why

`ip addr add 10.50.0.10/24 dev enp0s8` puts the address on the interface immediately and records nothing on disk. The next boot starts from the netplan file or the NetworkManager connection, and the address is gone. That single fact is what most of this domain is about, so the grader always reads a file as well as the running kernel.

The reason the task insists on keeping the existing address is that both tools replace rather than merge. Netplan reads every file in `/etc/netplan` in lexical order and merges them key by key: a file named `60-lab.yaml` that sets `addresses:` for `enp0s8` overrides the `addresses:` key set by `50-cloud-init.yaml` instead of extending it. The interface then comes up with only the new address, the management address is gone, and the session dies at `netplan apply`. Editing the file that already owns the interface avoids the problem entirely. NetworkManager has the same trap in a different spelling: the bare property assigns, `+ipv4.addresses` appends, and `-ipv4.addresses` removes one entry. The method is a second way to lose an address on Rocky. `ipv4.method` decides where the interface's addresses come from, and switching a connection from `auto` to `manual` stops the DHCP client, so the leased address is gone the moment the connection is brought up again.

`netplan try` exists for exactly this situation. It applies the configuration, waits 120 seconds for confirmation, and rolls back if the terminal goes away. On the interface carrying the session it is the difference between a mistake that costs 10 seconds and one that costs the host.

The connected route is worth checking as well as the address. An address written with the wrong prefix length still shows up in `ip addr`, but `ip -j route show dev enp0s8` then carries the wrong network, and nothing on that subnet answers.

## Verify

```bash
ip -j addr show enp0s8
ip -j route show dev enp0s8            # expect "dst":"10.50.0.0/24"
ping -c1 -W2 10.50.0.10

grep -R '10.50.0' /etc/netplan/                        # Ubuntu persistence
nmcli -g ipv4.method,ipv4.addresses con show "System enp0s8"   # Rocky persistence, method manual or auto
```

## Docs

- `man 5 netplan` for the `ethernets`, `addresses` and `dhcp4` keys and the file merge order
- `man 8 netplan-try` and `man 8 netplan-apply` for the two ways to activate a change
- `man 1 nmcli` for `con mod`, and the `+property` and `-property` forms
- `man 5 nm-settings-nmcli` for `ipv4.method` and `ipv4.addresses`
- `man 8 ip-address` and `man 8 ip-route` for the runtime commands and the `-j` output
