# Q17. Allow only ssh, http, https and icmp, persistent, without blocking the exam ports

This is the most reported task family in the whole exam, named by seven independent candidate reports.

Setup has given this host a second, private network. The host is `10.99.17.1` and a peer host is `10.99.17.2`. Six services are listening on the host address: ports `80`, `9999`, `8080`, `4505`, `4506`, and the ssh daemon on `22`.

Build a packet filter for incoming traffic that:

1. accepts ssh on `22/tcp`, http on `80/tcp` and https on `443/tcp`
2. accepts ICMP, so the host still answers `ping`
3. accepts traffic that belongs to a connection this host started, and traffic on the loopback interface
4. **accepts `8080/tcp`, `4505/tcp` and `4506/tcp`**
5. drops everything else, which for this test means `9999/tcp`
6. is still there after a reboot

Point 4 is not optional and it is not decoration. The Linux Foundation exam instructions say that ports `8080`, `4505` and `4506` must never be blocked, in an interactive command or in a saved configuration file. `4505` and `4506` are the ports the grading and orchestration layer uses, so a default drop policy without an explicit accept for them ends the exam session. The verifier here opens all three from the peer, so a naive default-drop policy fails this practice question instead of teaching you a habit that would cost you the real one.

Accept rules go in **before** the drop policy. The other order cuts your own session on the spot.

On Ubuntu use `nft` and save the ruleset to `/etc/nftables.conf`, or use `ufw`. On Rocky, `firewalld` is already running and `firewall-cmd --permanent` is the natural tool. Setup prints which one this host has.

The grader tests behaviour from the peer, so the rules have to actually work, and then reads the file that would restore them at the next boot. Writing the file without enabling the service that loads it scores half the task.

If you lock yourself out, open the VirtualBox console and run `nft flush ruleset`, or `ufw disable`, or `firewall-cmd --panic-off`.
