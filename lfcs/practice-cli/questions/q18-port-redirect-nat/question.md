# Q18. Redirect a port and masquerade a subnet, persistent

Setup has built two small networks around this host, so it sits in the middle like a router.

- Inside: peer `10.99.18.2`, host `10.99.18.1`, and the peer's default route points at the host.
- Outside: peer `10.99.118.2` running a web server, host `10.99.118.1`.
- An application on this host listens on `10.99.18.1:8080` and answers `nat-ok`.

Do two things, and make both survive a reboot.

1. **Redirect a port.** Traffic arriving on `8081/tcp` must be served by the application already listening on `8080`. After the change, `curl http://10.99.18.1:8081/` run from the inside peer returns the same page as port 8080.

2. **Masquerade the inside network.** Traffic from `10.99.18.0/24` that this host forwards out to the outside network must leave with this host's own address. The outside web server logs the address it sees, and after the change it must log `10.99.118.1` and not `10.99.18.2`.

Forwarding has to be on for masquerade to do anything, and it is graded both live and in a file under `/etc/sysctl.d/`.

Two notes on the exam ports. Redirecting some other port **to** 8080 is fine and is exactly what this task asks. Redirecting or dropping traffic **on** 8080, 4505 or 4506 is not, and the verifier checks that port 8080 still answers directly from the peer.

Test the redirect from the peer. The prerouting hook never sees traffic the host generates itself, so `curl localhost:8081` fails even when the rule is perfect.
