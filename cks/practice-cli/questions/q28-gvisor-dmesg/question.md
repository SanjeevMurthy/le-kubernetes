# Q28. Run a Pod under gVisor and capture dmesg

gVisor (`runsc`) is installed on the worker node and registered as a containerd runtime handler, but the cluster has no `RuntimeClass` for it.

1. Create a `RuntimeClass` named `gvisor` that uses the handler `runsc`.

2. In namespace `gvisor-lab`, create a Pod named `gvisor-test` from image `nginx:1.27` that runs under that RuntimeClass. It has to be scheduled on the worker node, because that is where `runsc` is installed.

3. Prove the Pod really is sandboxed: read the kernel ring buffer from inside it and write the output to `/opt/course/28/dmesg.txt` (or `$COURSE_DIR/28/dmesg.txt` on this lab).

A Pod that merely names the RuntimeClass is not enough. The deliverable has to show the sandbox kernel.
