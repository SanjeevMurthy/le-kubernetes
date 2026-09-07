# Q22. The web app is unreachable from the peer, find and fix two causes (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. Confirm the symptom, then work inwards from the host.**

```bash
ip netns exec dbg-peer curl --max-time 3 -sS http://10.99.22.1:8082/    # times out
systemctl is-active labapp
curl --max-time 3 -sS http://127.0.0.1:8082/                            # app-ok, so it runs
curl --max-time 3 -sS http://10.99.22.1:8082/                           # refused
```

The application answers on loopback and refuses on the host's own network address. That is the first cause, and it is not a firewall.

**2. Find the bind address.**

```bash
ss -tulpn | grep 8082
systemctl cat labapp
```

`ss` shows `127.0.0.1:8082`, and `systemctl cat` shows why: the unit passes `--bind 127.0.0.1`.

**3. Fix it where it persists, which is the unit.**

```bash
systemctl edit --full labapp        # or edit /etc/systemd/system/labapp.service
```

Change the bind address to `0.0.0.0`:

```
ExecStart=/usr/bin/python3 -u -m http.server 8082 --bind 0.0.0.0 --directory /srv/labapp
```

```bash
systemctl daemon-reload
systemctl restart labapp
ss -H -ltn | grep 8082              # 0.0.0.0:8082 now
curl --max-time 3 -s http://10.99.22.1:8082/   # app-ok from the host
```

The peer still sees nothing. That is the second cause.

**4. Find the rule.**

```bash
nft list ruleset | grep -n 8082
tcpdump -ni any port 8082 -c 5 &     # the SYN arrives and nothing answers
ip netns exec dbg-peer curl --max-time 3 http://10.99.22.1:8082/
```

**5. Delete the rule from the running kernel and from the file it was saved in.**

```bash
nft -a list ruleset | grep -B4 8082           # the -a form prints rule handles
nft delete table inet labq22                  # the whole lab table, in one step

grep -n 8082 /etc/nftables.conf               # /etc/sysconfig/nftables.conf on Rocky
vim /etc/nftables.conf                        # remove the table block that drops 8082
nft -f /etc/nftables.conf                     # optional, proves the file still parses
```

**6. Test from the peer and record the answer.**

```bash
ip netns exec dbg-peer curl --max-time 3 -s http://10.99.22.1:8082/   # app-ok

mkdir -p /opt/course/22
cat >/opt/course/22/causes.txt <<'TXT'
labapp.service bound the socket to 127.0.0.1 instead of 0.0.0.0, so only the host could reach it
an nft rule dropped tcp dport 8082, live and in the saved nftables configuration file
TXT
```

## Why

Two failures that look identical from the client are the shape of this task, and the whole skill is telling them apart without guessing.

A socket bound to `127.0.0.1` accepts connections that arrive over the loopback interface and nothing else. From outside the machine the kernel has nothing listening on that address and port, so it answers with a TCP reset and the client reports "connection refused" immediately. A dropped packet produces no answer at all, so the client waits for its timeout. Refused fast and hung until timeout are two different diagnoses, and `curl --max-time 3` makes the difference visible without a stopwatch.

`ss -tulpn` is the first command for a reason. It prints the local address as well as the port, and with root it names the process holding the socket. If the local address is `127.0.0.1`, the fix is in the application's configuration and no firewall rule will ever help. If it is `0.0.0.0` or `*`, the service is reachable in principle and the problem is between the two machines.

The persistence half is what makes this an LFCS question rather than a puzzle. Deleting a live nft rule fixes the symptom until the next boot, when the saved ruleset is loaded again and the port goes dark a second time. The same is true on the application side: restarting the process by hand with a different bind address works until the unit restarts it with the old one. Both fixes have to land in a file.

`tcpdump -ni any port 8082` settles any remaining doubt about where a packet dies. If the SYN appears in the capture and nothing goes back, the packet reached the host and something on the host dropped it. If it never appears, the problem is routing or the peer. The `-n` matters on a host with a broken resolver, because reverse lookups stall the capture.

## Verify

```bash
systemctl is-active labapp
systemctl cat labapp | grep bind
ss -H -ltn | grep 8082                      # 0.0.0.0:8082, not 127.0.0.1:8082

nft list ruleset | grep -c 8082             # 0
grep -c 8082 /etc/nftables.conf 2>/dev/null # 0

curl --max-time 3 -s http://10.99.22.1:8082/
ip netns exec dbg-peer curl --max-time 3 -s http://10.99.22.1:8082/
cat /opt/course/22/causes.txt
```

## Docs

- `man 8 ss` for `-t`, `-u`, `-l`, `-p`, `-n` and reading the local address column
- `man 8 nft` for `list ruleset`, rule handles and `delete`
- `man 8 tcpdump` for `-n`, `-i any` and a port filter
- `man 1 systemctl` for `cat`, `edit` and `daemon-reload`
- `man 5 systemd.service` for `ExecStart` and where a unit's overrides live
- `man 1 curl` for `--max-time` and the difference between a refusal and a timeout
