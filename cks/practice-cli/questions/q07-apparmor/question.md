# Q7. AppArmor Profile on a Pod

**Host:** the worker node named in the setup output (root shell: `sudo -i`).

The profile file `/etc/apparmor.d/k8s-deny-write` exists on that worker but has **not** been loaded into the kernel. It defines a profile called `k8s-deny-write` that denies all filesystem writes. Namespace `apparmor-lab` exists and is empty.

1. Load `/etc/apparmor.d/k8s-deny-write` on the worker node so that `k8s-deny-write` appears in **enforce** mode in `aa-status`.
2. Create pod `secure-pod` in namespace `apparmor-lab`, image `busybox:1.36`, command `sleep 3600`, confined by the `k8s-deny-write` profile (`securityContext.appArmorProfile` with `type: Localhost` and `localhostProfile: k8s-deny-write`).
3. The pod must be **Running**, and a write inside the container (for example `touch /tmp/apparmor-probe`) must be **denied**.
