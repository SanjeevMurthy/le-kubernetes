# Q17. Allow only ssh, http, https and icmp, persistent, without blocking the exam ports (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. Read the ruleset before writing anything.**

```bash
nft list ruleset
ss -H -ltn
ufw status 2>/dev/null; firewall-cmd --state 2>/dev/null
```

**2a. Ubuntu with nft: build the chain in the safe order.**

```bash
nft add table inet filter
nft add chain inet filter input '{ type filter hook input priority 0 ; policy accept ; }'

nft add rule inet filter input ct state established,related accept
nft add rule inet filter input iif lo accept
nft add rule inet filter input ip protocol icmp accept
nft add rule inet filter input ip6 nexthdr icmpv6 accept
nft add rule inet filter input tcp dport { 22, 80, 443 } accept
nft add rule inet filter input tcp dport { 8080, 4505, 4506 } accept

nft chain inet filter input '{ policy drop ; }'
```

The chain is created with `policy accept` and switched to `policy drop` only once every accept rule is in place. Doing it the other way round drops the session between the two commands.

Then persist both halves:

```bash
nft list ruleset > /etc/nftables.conf
systemctl enable --now nftables
```

**2b. Ubuntu with ufw, if you prefer the front end.**

```bash
ufw allow 22/tcp
ufw allow 80,443/tcp
ufw allow 8080,4505,4506/tcp
ufw default deny incoming
ufw --force enable
ufw status numbered
```

**2c. Rocky with firewalld.**

```bash
firewall-cmd --get-active-zones
firewall-cmd --permanent --add-service=ssh --add-service=http --add-service=https
firewall-cmd --permanent --add-port=8080/tcp --add-port=4505/tcp --add-port=4506/tcp
firewall-cmd --reload
firewall-cmd --list-all
systemctl enable firewalld
```

`--permanent` writes the zone file and changes nothing until `--reload`. Leaving out the reload is the single most common firewalld mistake.

**3. Test from the peer, not from the host.**

```bash
ip netns exec fw-peer curl -s --max-time 3 http://10.99.17.1:80/          # answers
ip netns exec fw-peer ping -c1 -W3 10.99.17.1                            # answers
ip netns exec fw-peer curl -s --max-time 3 http://10.99.17.1:9999/       # times out
for p in 22 8080 4505 4506; do
  ip netns exec fw-peer timeout 3 bash -c "exec 3<>/dev/tcp/10.99.17.1/$p" \
    && echo "$p open" || echo "$p BLOCKED"
done
```

**4. Read the saved file back before moving on.**

```bash
grep -E '8080|4505|4506' /etc/nftables.conf
systemctl is-enabled nftables
firewall-cmd --permanent --list-all
```

## Why

Two halves decide this task, and candidates lose marks on both.

The first is the order of operations. An nftables chain has a policy and a list of rules, and the policy applies to any packet no rule accepted. Setting `policy drop` on a chain that has no accept rules yet drops the packets of the SSH session carrying the command, and there is no second command. Adding the accept rules first, then flipping the policy, means the worst case is a rule that is too permissive rather than a host that cannot be reached. The same logic is why `ufw default deny incoming` comes after the `ufw allow` lines and why `firewall-cmd --permanent` waits for a `--reload`.

The second is that persistence is a pair. `nft add rule` changes the running kernel only. `nft list ruleset > /etc/nftables.conf` writes the file, and `systemctl enable nftables` is what makes something read that file at boot. Doing one without the other looks correct in `nft list ruleset` and comes back empty, or comes back with a drop policy and no accept rules, after a reboot. The saved file deserves its own read: a persisted default drop that omits the exam ports is a rule that has not caused any harm yet and will at the next boot.

Ports 8080, 4505 and 4506 are a hard rule from the Linux Foundation, not lab colour. 4505 and 4506 are the SaltStack publish and return ports that the exam infrastructure uses to reach the machine, and 8080 is used by the exam environment as well. Blocking them, live or in a saved file, ends the session. The habit worth building is to add the accept for all three in the same command as ssh, before anything sets a drop policy, on every firewall task.

One tool per host. ufw and firewalld both generate nftables rules underneath, so `nft flush ruleset` silently deletes what either of them installed and `nft add rule` survives only until the front end reloads. Reading `nft list ruleset` is still the honest way to see what the kernel holds, whichever tool wrote it.

Finally, ICMP is a rule of its own. A host that accepts port 80 and drops ICMP looks unreachable to `ping` while serving pages perfectly, which is why troubleshooting starts at the port and not at the host.

## Verify

```bash
nft list ruleset
ss -H -ltn

ip netns exec fw-peer curl -s --max-time 3 http://10.99.17.1:80/
ip netns exec fw-peer ping -c1 -W3 10.99.17.1
ip netns exec fw-peer curl -s --max-time 3 http://10.99.17.1:9999/ || echo blocked
for p in 8080 4505 4506; do ip netns exec fw-peer timeout 3 bash -c "exec 3<>/dev/tcp/10.99.17.1/$p" && echo "$p open"; done

grep -cE 'dport|accept|ACCEPT|port=' /etc/nftables.conf 2>/dev/null
systemctl is-enabled nftables 2>/dev/null
ufw status verbose 2>/dev/null
firewall-cmd --permanent --list-all 2>/dev/null
```

## Docs

- `man 8 nft` for tables, chains, hooks, priorities, `ct state` and `policy`
- `man 8 ufw` for `allow`, `default` and `status numbered`
- `man 1 firewall-cmd` and `man 5 firewalld.zone` for `--permanent`, `--reload` and the zone files
- `man 8 iptables` and `man 8 iptables-save` for the older syntax a grader still accepts
- `man 8 netfilter-persistent` for the Debian and Ubuntu iptables save hook
