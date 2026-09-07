# Q12. Static IPv4 on the second NIC, persistent

This host has two network interfaces. The first one carries the default route. The second one is the lab network interface, and the setup output names it.

Give the second interface an extra static IPv4 address:

- `10.50.0.10/24` on Ubuntu
- `10.50.0.20/24` on Rocky

The setup output prints the exact address for this host, so read it before you start.

Three conditions decide the grade:

1. The address is live on that interface when you finish. The grader reads `ip -j addr show <nic>` and `ip -j route show dev <nic>`.
2. The address is still there after a reboot. The grader reads the netplan YAML on Ubuntu and the NetworkManager keyfile on Rocky. An address added with `ip addr add` scores nothing.
3. Every address the interface already had is still on it. That interface may be carrying your SSH session, and losing its address costs you the host.

Condition 3 is the one that catches people. On Ubuntu a second netplan file that declares `addresses:` for the same interface replaces the list rather than adding to it. On Rocky a bare `nmcli con mod <con> ipv4.addresses ...` replaces the list as well.

Leave the interface's addressing method as you found it. The task is an extra address, not a change of method. On Rocky, if the connection is holding a DHCP lease, `nmcli con mod <con> ipv4.method manual` ends the lease and takes the address it gave you with it, which is condition 3 failed. NetworkManager applies the addresses in `ipv4.addresses` under `auto` as well as under `manual`, so the static address lands on top of the lease. The grader checks only that IPv4 is still enabled on the connection, meaning the method is `manual` or `auto` and not `disabled`, because a disabled connection applies nothing at boot.

Do not touch the interface that carries the default route.
