# Q18. Redirect a port and masquerade a subnet, persistent (solution)

## Steps

**1. Turn forwarding on, now and for the next boot.**

```bash
sysctl -w net.ipv4.ip_forward=1
echo 'net.ipv4.ip_forward = 1' > /etc/sysctl.d/90-forward.conf
sysctl --system
sysctl -n net.ipv4.ip_forward
```

**2a. nftables: one table, two chains, two rules.**

```bash
nft add table ip nat
nft add chain ip nat prerouting  '{ type nat hook prerouting priority dstnat ; }'
nft add chain ip nat postrouting '{ type nat hook postrouting priority srcnat ; }'

nft add rule ip nat prerouting tcp dport 8081 redirect to :8080
nft add rule ip nat postrouting ip saddr 10.99.18.0/24 oif veth-nat-out masquerade
```

`oif` can be left out, in which case every interface masquerades traffic from that source network. Naming the outgoing interface is the tidier answer.

**2b. iptables, which a grader accepts just as readily.**

```bash
iptables -t nat -A PREROUTING -p tcp --dport 8081 -j REDIRECT --to-port 8080
iptables -t nat -A POSTROUTING -s 10.99.18.0/24 -j MASQUERADE
iptables -t nat -S
```

**2c. firewalld on Rocky.**

```bash
firewall-cmd --permanent --add-forward-port=port=8081:proto=tcp:toport=8080
firewall-cmd --permanent --add-masquerade
firewall-cmd --reload
firewall-cmd --list-all
```

**3. Persist the ruleset, and the service that reloads it.**

```bash
nft list ruleset > /etc/nftables.conf          # /etc/sysconfig/nftables.conf on Rocky
systemctl enable --now nftables
grep -E 'redirect|masquerade' /etc/nftables.conf
```

**4. Test from the peer.**

```bash
ip netns exec nat-peer curl -s --max-time 3 http://10.99.18.1:8081/    # nat-ok
ip netns exec nat-peer curl -s --max-time 3 http://10.99.118.2/        # reaches the outside
```

The outside server logs the source address of each request, so the second command is what proves the masquerade.

## Why

The prerouting hook runs before the routing decision, on packets that arrived on a wire. Locally generated traffic never passes through it, which is why `curl localhost:8081` on the host itself returns "connection refused" while the rule is working perfectly for every other machine. Testing a redirect from the host is the classic way to conclude a correct rule is broken and then break it while fixing it.

`REDIRECT` and `DNAT` are neighbours with different jobs. `REDIRECT` sends the packet to a port on the machine that received it, and it needs no destination address. `DNAT` sends it to some other machine, which then also needs a route back through this host, or the reply never returns.

Masquerade is source NAT with the address chosen at send time from the outgoing interface. It only ever sees a packet if the packet is being forwarded, and the kernel only forwards when `net.ipv4.ip_forward` is 1. `sysctl -w` sets that for the running kernel and writes nothing, so a NAT task that works today and fails after a reboot usually fails on this one line rather than on the rules. The persistent form is a file under `/etc/sysctl.d/` followed by `sysctl --system`.

The nat table is consulted for the first packet of a connection only. Once conntrack has an entry, later packets follow the translation already recorded, so changing a rule and retesting the same connection shows the old behaviour. `conntrack -F` clears the table, and opening a fresh connection has the same effect.

nat chains need a priority, and the readable spelling is the named one: `dstnat` for prerouting, `srcnat` for postrouting. A nat chain declared with the filter priority still loads and quietly does the wrong thing relative to the filter rules.

## Verify

```bash
sysctl -n net.ipv4.ip_forward                       # 1
nft list ruleset | grep -E 'redirect|dnat|masquerade'
iptables -t nat -S | grep -E 'REDIRECT|MASQUERADE'

ip netns exec nat-peer curl -s --max-time 3 http://10.99.18.1:8081/
ip netns exec nat-peer curl -s --max-time 3 http://10.99.18.1:8080/    # still answers directly
ip netns exec nat-peer curl -s --max-time 3 http://10.99.118.2/

grep -E 'redirect|masquerade|forward-port' /etc/nftables.conf /etc/sysconfig/nftables.conf 2>/dev/null
grep -R ip_forward /etc/sysctl.conf /etc/sysctl.d/
systemctl is-enabled nftables 2>/dev/null; firewall-cmd --permanent --list-all 2>/dev/null
```

## Docs

- `man 8 nft` for the nat table, the `dstnat` and `srcnat` priorities, `redirect` and `masquerade`
- `man 8 iptables` and `man 8 iptables-extensions` for `REDIRECT`, `DNAT` and `MASQUERADE`
- `man 1 firewall-cmd` for `--add-forward-port` and `--add-masquerade`
- `man 5 sysctl.d` and `man 8 sysctl` for the persistent forwarding setting
- `man 8 conntrack` for flushing translations while testing
