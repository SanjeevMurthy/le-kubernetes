# Q22. The web app is unreachable from the peer, find and fix two causes

A web application runs on this host as `labapp.service` and should answer on port `8082`. From the peer host it does not answer at all.

- this host is `10.99.22.1`
- the peer is `10.99.22.2`, in the network namespace `dbg-peer`
- test from the peer with `ip netns exec dbg-peer curl --max-time 3 http://10.99.22.1:8082/`
- a working application answers `app-ok`

There are **two** independent causes. Fixing one of them changes nothing that the peer can see, so keep looking after the first.

Fix both, so that:

1. the peer gets `app-ok` from `http://10.99.22.1:8082/`
2. both fixes survive a reboot. One of them lives in the systemd unit for the application. The other one has been saved into the distribution's nftables file as well as loaded into the running kernel, so deleting the live rule alone leaves it waiting for the next boot.

Then write what you found to `/opt/course/22/causes.txt`, one cause per line, naming the bind address for one and the firewall rule for the other.

Start with `ss -tulpn`. A socket bound to `127.0.0.1` is not a firewall problem, and reaching for `nft` first is how people spend ten minutes on the wrong half.
