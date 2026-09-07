# Q19. Put the second NIC into a bridge, persistent (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. Write down what the interface has now.**

```bash
ip -br addr show enp0s8
ip route
grep -l enp0s8 /etc/netplan/*.yaml          # Ubuntu
nmcli -t -f NAME,DEVICE con show --active   # Rocky
```

**2a. Ubuntu: one netplan file describes both halves of the change.**

Edit the file that already owns the interface, so nothing is left declaring an address on the port:

```yaml
network:
  version: 2
  ethernets:
    enp0s8:
      dhcp4: false
  bridges:
    br0:
      interfaces: [enp0s8]
      addresses:
        - 192.168.56.10/24
      parameters:
        stp: false
        forward-delay: 0
```

```bash
chmod 600 /etc/netplan/50-cloud-init.yaml
netplan try
```

`netplan try` applies the change, waits for a confirmation, and rolls back if the session dies. On the interface carrying the session that is the difference between a typo and a lost host.

**2b. Rocky: three connections, added in one go.**

```bash
nmcli con add type bridge con-name br0 ifname br0 \
  ipv4.method manual ipv4.addresses 192.168.56.20/24 bridge.stp no
nmcli con add type ethernet con-name br0-enp0s8 ifname enp0s8 master br0 slave-type bridge
nmcli con mod "System enp0s8" ipv4.method disabled ipv6.method ignore
nmcli con up br0
nmcli con up br0-enp0s8
```

The old ethernet connection has to stop claiming the address, or NetworkManager brings it back on the port the next time it activates.

**3. Confirm the live state.**

```bash
ip -d link show br0            # link/ether ... bridge
bridge link                    # enp0s8 ... master br0 state forwarding
ip -br addr show br0           # the address is here now
ip -br addr show enp0s8        # and not here
ping -c1 192.168.56.1
```

## Why

A bridge is a software switch. Frames arriving on any port are forwarded to the other ports by destination MAC address, which is what lets virtual machine interfaces share one physical NIC and appear directly on the physical network. Because a port is a switch port rather than a host interface, it cannot hold an IP address: the address belongs to the bridge device, which is the host's own port on that switch. Enslaving an interface without moving its address is the failure mode of this task, and on the interface carrying the session it costs the host.

`ip link` alone will not show the relationship. `bridge link` and `ip -d link show enp0s8` both name the master, and `/sys/class/net/enp0s8/master` is the same fact in the kernel's own words.

Spanning tree is worth turning off in a lab. With STP on, a new port goes through listening and learning states before it forwards, which takes about 30 seconds with the default forward delay. A test run immediately after the change then fails on a configuration that is entirely correct, and the usual reaction is to change something that was right.

Netplan and NetworkManager describe the same result differently. Netplan has a `bridges:` section listing member interfaces, and one file can describe the port and the bridge together, which is why `netplan try` can apply the whole change atomically. NetworkManager models each side as its own connection profile: one of type `bridge` that owns the address, and one of type `ethernet` with `master br0`. Leaving the interface's old connection with a manual address means two profiles fight over the same device.

## Verify

```bash
ip -d -j link show br0 | grep -o 'bridge'
test -d /sys/class/net/br0/bridge && echo br0-is-a-bridge
basename "$(readlink /sys/class/net/enp0s8/master)"    # br0
ip -j addr show br0
ping -c1 -W2 192.168.56.1

grep -n -A6 'bridges' /etc/netplan/*.yaml                        # Ubuntu persistence
nmcli -g connection.type con show br0                            # Rocky persistence
nmcli -g connection.master,connection.slave-type con show br0-enp0s8
```

## Docs

- `man 5 netplan` for the `bridges:` section, `interfaces:` and `parameters:`
- `man 8 bridge` for `bridge link` and the port states
- `man 8 ip-link` for `type bridge` and `master`
- `man 1 nmcli` and `man 5 nm-settings-nmcli` for `con add type bridge`, `master` and `slave-type`
- `man 8 netplan-try` for the rollback that makes this change safe
