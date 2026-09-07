# Q43. Which pod calls the kill syscall

**Host:** the worker node named in the setup output (root shell: `sudo -i`).

Namespace `strace-lab` holds two Deployments scheduled on that worker, `worker-a` and `worker-b`. One of them keeps issuing the `kill` system call every second. The other one is idle and is doing nothing wrong. The manifests give nothing away, so find the answer at the syscall level.

1. On the worker, list the running containers with `crictl ps` and map each one to its process id:

   ```
   crictl inspect --output go-template --template '{{.info.pid}}' <container-id>
   ```

2. Trace each of those processes for a few seconds and see which one calls `kill`:

   ```
   strace -p <pid> -f -e trace=kill -o /tmp/trace.log
   ```

3. Map the container that made the calls back to its Pod, and write that Pod as `<namespace>/<pod-name>` on a single line in `/opt/course/43/pod.txt` (or `$COURSE_DIR/43/pod.txt` on this lab). That file is written on the host you are running the practice CLI from.

4. Stop the offending workload by deleting its **Deployment**. Deleting only the Pod is not enough, because the Deployment creates a replacement.

Leave the innocent Deployment running with its one replica, and leave the namespace in place.
