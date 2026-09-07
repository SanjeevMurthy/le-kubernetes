# Q8. Seccomp RuntimeDefault + Custom Profile

**Host:** the worker node named in the setup output (root shell: `sudo -i`); both pods must run on that node.

The kubelet seccomp root on that worker is `/var/lib/kubelet/seccomp`, and a custom profile has already been placed at `/var/lib/kubelet/seccomp/profiles/audit.json` (`defaultAction: SCMP_ACT_LOG`). `localhostProfile` values are relative to the seccomp root. Namespace `seccomp-lab` exists and is empty.

1. Create pod `audited` in namespace `seccomp-lab`, image `busybox:1.36`, command `sleep 3600`, using seccomp `type: Localhost` with `localhostProfile: profiles/audit.json`.
2. Create pod `default-seccomp` in namespace `seccomp-lab`, image `busybox:1.36`, command `sleep 3600`, using seccomp `type: RuntimeDefault`.
3. Both pods must be **Running**, and the `audited` container's process must really be confined: `/proc/<pid>/status` on the worker must report `Seccomp:	2` (filter mode), where the pid comes from `crictl inspect --output go-template --template '{{.info.pid}}' <container-id>`.
