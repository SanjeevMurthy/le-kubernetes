# Q42. Host hardening: users, sudo and kernel modules

**Host:** the worker node named in the setup output (root shell: `sudo -i`).

An audit of that worker turned up a leftover contractor account and a kernel module nothing on the node uses.

1. The local account `tempadmin` must stay on the node for the audit trail, but nobody may log in as it any more. Lock its password and set its login shell to `/usr/sbin/nologin`. Do **not** delete the account and do not delete its home directory.

2. `tempadmin` has a sudo drop-in at `/etc/sudoers.d/tempadmin` granting `NOPASSWD:ALL`. Remove it, so `sudo -l -U tempadmin` reports no sudo rights at all.

3. `tempadmin` is a member of the supplementary group `lab-ops`. Take it out of that group. The group itself may stay.

4. The `sctp` kernel module is loaded and nothing on this node needs it. Unload it, and make sure it stays out after a reboot by writing a blacklist to `/etc/modprobe.d/blacklist-sctp.conf`. Use that exact path, so the cleanup can remove it again.

The setup output says whether this kernel has an `sctp` module. If it does not, step 4 is not graded on this lab, and the rest of the question still applies.
