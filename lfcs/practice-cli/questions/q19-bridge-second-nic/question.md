# Q19. Put the second NIC into a bridge, persistent

Virtual machines on this host need a layer 2 bridge to sit on. The second network interface is going to carry it. Setup prints the interface name and the address it currently holds.

Build a bridge called `br0`:

1. `br0` exists and is a bridge device
2. the second interface is a port of `br0`
3. the address the interface holds today is on `br0` instead, with the same prefix length
4. the host still reaches its gateway afterwards
5. all of it survives a reboot, in the netplan YAML on Ubuntu or in NetworkManager connection files on Rocky

A bridge port cannot keep an address of its own, so the address moves to `br0` in the same change. That is the whole difficulty of this task.

**This interface may be carrying your session.** On Ubuntu use `netplan try`, which rolls the change back by itself after 120 seconds if the terminal goes away. On Rocky, either work from the VirtualBox console, or accept that `nmcli con up br0` cuts the connection for a moment and comes back once the bridge has the address. If you do lose the host, the console is still there and `ip link del br0` undoes the live half.

Turn spanning tree off, or a correct bridge takes about 30 seconds to start forwarding and an immediate test looks like a failure.
