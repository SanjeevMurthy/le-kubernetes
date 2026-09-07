# Q34. AppArmor: the profile name is not the file name

**Host:** the worker node named in the setup output (root shell: `sudo -i`).

The file `/etc/apparmor.d/k8s-lab-deny-write` sits on that worker. It has not been loaded into the kernel. A colleague has already written a Pod manifest for it at `/opt/course/34/pod.yaml` (or `$COURSE_DIR/34/pod.yaml` on this lab), but the Pod does not start correctly.

1. Load the profile from that file so it shows up in **enforce** mode in `aa-status`.

2. Fix `pod.yaml` and apply it. The Pod is `guarded` in namespace `apparmor-trap`, and it has to end up **Running** and confined by that profile.

3. A write inside the container (for example `touch /root/x`) must be **denied**, while reading still works.

Do not rename the file, and do not rewrite what it contains. Read it first: everything you need to fix the manifest is in there.
