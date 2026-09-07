# Q30. seccomp: block mkdir with a Localhost profile

The kubelet seccomp root on the worker node is `/var/lib/kubelet/seccomp`, and `/var/lib/kubelet/seccomp/profiles/` already exists and is empty.

1. On the worker node, write a seccomp profile to `/var/lib/kubelet/seccomp/profiles/no-mkdir.json` that allows every system call **except** directory creation, which must fail with an error rather than kill the process.

2. In namespace `seccomp-lab`, create a Pod named `sandboxed` from image `busybox:1.36` running `sleep 3600`, using that profile as a `Localhost` seccomp profile. The Pod has to be scheduled on the worker node, because the profile file only exists there.

3. The Pod must reach `Running`, and ordinary work inside it must still succeed. Only directory creation is blocked.

4. Run a directory creation inside the Pod, and write the error it produces to `/opt/course/30/result.txt` (or `$COURSE_DIR/30/result.txt` on this lab).
