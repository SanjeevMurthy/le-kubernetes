# Q13. Persistent static route (solution)

## Steps

**1. Look at the routing table first, and find the gateway.**

```bash
ip route
ip -br addr show enp0s8          # the interface subnet gives the gateway, here 192.168.56.1
ip route get 10.200.0.5          # right now this leaves through the default route
```

**2a. Ubuntu: add a `routes:` list to the netplan file that owns the interface.**

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
      routes:
        - to: 10.200.0.0/16
          via: 192.168.56.1
```

```bash
chmod 600 /etc/netplan/50-cloud-init.yaml
netplan try                       # rolls back on its own if the session dies
```

**2b. Rocky: append the route to the connection.**

```bash
nmcli -t -f NAME,DEVICE con show --active
nmcli con mod "System enp0s8" +ipv4.routes "10.200.0.0/16 192.168.56.1"
nmcli con up "System enp0s8"
```

`+ipv4.routes` appends. The bare `ipv4.routes` property replaces the whole list, which silently drops any route already there.

**3. Confirm it landed.**

```bash
ip -j route show 10.200.0.0/16
ip route get 10.200.0.5           # expect via 192.168.56.1 dev enp0s8
```

If the gateway is not on a subnet the host is directly connected to, the kernel refuses with "Nexthop has invalid gateway". Fix the address on the interface first, then add the route.

## Why

A route is state in the kernel's forwarding information base. `ip route add` writes it there and nowhere else, so it lives exactly as long as the kernel does. The persistent form is a property of the interface configuration, which is why both netplan and NetworkManager keep routes next to addresses rather than in a file of their own.

Netplan's old `gateway4:` key is deprecated and ignored on current releases. A default route is written as an entry inside `routes:` with `to: default`, and any other route as `to: <cidr>` with `via: <gateway>`. Writing `gateway4:` produces a warning that is easy to miss and a routing table that never changes.

`ip route get` is worth more than `ip route` when checking work. It asks the kernel which route it would actually use for one destination, so it resolves metric ties and more specific prefixes that a printed table hides. If `ip route get 10.200.0.5` still names the default gateway, the new route exists but something more specific or with a lower metric is winning.

The reason the grader reads a file as well is that this is the single most common way to lose marks in this domain. A route that is right now and gone after a reboot is worth nothing on the exam.

## Verify

```bash
ip -j route show 10.200.0.0/16
ip route get 10.200.0.5

grep -A3 -n 'routes' /etc/netplan/*.yaml               # Ubuntu persistence
nmcli -g ipv4.routes con show "System enp0s8"          # Rocky persistence
```

## Docs

- `man 8 ip-route` for `add`, `get`, `via`, `dev` and metrics
- `man 5 netplan` for the `routes:` list, `to:` and `via:`
- `man 1 nmcli` for `con mod` and the `+property` form
- `man 5 nm-settings-nmcli` for the `ipv4.routes` syntax
