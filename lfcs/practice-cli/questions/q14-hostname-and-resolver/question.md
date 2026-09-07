# Q14. Hostname, hosts file, DNS servers and search domain

Setup has renamed this host to `lfcs-unset` and stripped its resolver configuration. Put all of it back.

1. Set the static hostname to `node1.lab.local` on Ubuntu, or `node2.lab.local` on Rocky. The setup output prints the name for this host. It must still be that name after a reboot.

2. Make the name `node9` resolve to `192.168.56.90` without asking a DNS server. `getent hosts node9` must print that address, and `node9.lab.local` must resolve to it too.

3. Configure two DNS servers, `1.1.1.1` and `9.9.9.9`, and the search domain `lab.local`.

The resolver half is graded twice: once live, from `resolvectl dns` and `resolvectl domain` where `systemd-resolved` runs, or from `/etc/resolv.conf` where it does not, and once from the file that survives a reboot. That file is the netplan YAML on Ubuntu, the NetworkManager keyfile on Rocky, or `/etc/systemd/resolved.conf` and its drop-in directory.

Editing `/etc/resolv.conf` by hand does not count. Where `systemd-resolved` owns the machine that file is a symlink into `/run`, and where NetworkManager owns it the file is rewritten on the next connection change. Both throw the edit away.
