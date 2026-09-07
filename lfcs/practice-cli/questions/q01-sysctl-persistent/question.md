# Q01. Kernel parameters now and after reboot

This host routes traffic for a lab network and swaps far too early.

Set two kernel parameters:

- `net.ipv4.ip_forward` to `1`
- `vm.swappiness` to `10`

Both values must be in effect in the running kernel when you finish, and both must still be in effect after the host reboots.

The grader reads the live values with `sysctl -n`, and reads `/etc/sysctl.conf` and the files under `/etc/sysctl.d/` for the persistent half. A value set only with `sysctl -w` scores nothing.
