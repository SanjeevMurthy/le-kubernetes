# Q13. Persistent static route

The lab network has a router that reaches a remote range this host cannot see yet.

Add a static route for `10.200.0.0/16` through the gateway on the second network interface. The setup output names the interface and the gateway address, which is the `.1` address of the subnet the interface is already on. On the lab VMs that is `192.168.56.1`.

The route must be there twice over:

1. In the running kernel. The grader reads `ip -j route` and `ip route get 10.200.0.5`.
2. In the network configuration, so it comes back after a reboot. The grader reads the netplan YAML on Ubuntu and the NetworkManager keyfile on Rocky. A route added with `ip route add` scores nothing.

Do not change the default route, and do not remove any address the interface already carries.
