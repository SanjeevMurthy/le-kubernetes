# Q43. Which pod calls the kill syscall (solution)

## Steps

Everything up to the last step happens on the worker node, as root.

```bash
ssh <worker>
sudo -i
```

**1. List the candidate containers.** `crictl` talks to the container runtime directly, so it sees processes rather than API objects.

```bash
crictl ps --name worker
# CONTAINER      IMAGE     STATE     NAME     POD ID         POD
# 6b1f0c7a9d3e   busybox   Running   worker   9a2c...        worker-a-7c9f8b6d5-x2k4p
# c4d2e8f1a0b7   busybox   Running   worker   3f7e...        worker-b-64d7c9f8b-q8mn2
```

If the `POD` column is missing on an older crictl, take the pod id and resolve it:

```bash
crictl pods --id 9a2c...
```

**2. Map each container to a host pid.** The runtime knows it; there is no `jq` on the exam, so use a go-template.

```bash
crictl inspect --output go-template --template '{{.info.pid}}' 6b1f0c7a9d3e
# 24871
crictl inspect --output go-template --template '{{.info.pid}}' c4d2e8f1a0b7
# 24993
```

**3. Trace each pid for the one syscall the question names.** `-f` follows the children, which matters because the container's process is a shell that forks.

```bash
timeout 5 strace -p 24871 -f -e trace=kill -o /tmp/trace-a.log
timeout 5 strace -p 24993 -f -e trace=kill -o /tmp/trace-b.log

grep -c 'kill(' /tmp/trace-a.log    # several
grep -c 'kill(' /tmp/trace-b.log    # 0
```

Without `timeout`, run `strace` in the background and stop it with `kill %1` after a few seconds. The busy log looks like this:

```
24871 kill(1, 0)  = 0
```

**4. Name the Pod and record it.** The container was traced, so read the Pod name off the same `crictl ps` line, then confirm it in Kubernetes.

```bash
kubectl get pods -n strace-lab -o wide
mkdir -p /opt/course/43
echo "strace-lab/worker-a-7c9f8b6d5-x2k4p" > /opt/course/43/pod.txt
```

**5. Stop the workload at the right level.**

```bash
kubectl delete deploy worker-a -n strace-lab
kubectl get pods -n strace-lab       # only worker-b is left
```

Deleting the Pod alone puts a new one back within seconds, because the ReplicaSet behind the Deployment is still asking for one replica.

## Why

Runtime detection ends with a process, and a process is not an answer anybody can act on. The chain that closes the gap is always the same: syscall, pid, container, Pod, controller. `strace` gives the first two, `crictl inspect` joins pid to container, `crictl ps` joins container to Pod, and `kubectl` joins Pod to the Deployment that keeps recreating it. Falco automates the same walk and prints the Kubernetes fields directly, which is why it is the tool of choice in production. `strace` is what remains when Falco is not installed, or when the question is about a syscall no rule covers.

`crictl inspect --output go-template --template '{{.info.pid}}'` is worth learning as a fixed phrase. The pid it returns is the host pid, which is what `strace -p` needs: containers share the host kernel, so a container process is an ordinary process in the host's namespace with a different view of the filesystem and of its own pid. That is also why the trace shows `kill(1, 0)` while the host pid is 24871. Inside its pid namespace the process is 1.

`-e trace=kill` filters at the kernel interface rather than in the output, which keeps the log small enough to read and keeps the tracee fast enough to behave normally. `strace` stops the traced process at every filtered syscall, so tracing a busy production process without a filter is itself a small denial of service. `-f` is required whenever the target is a shell or any process that forks, because the interesting call is usually made by a child.

Deleting the Deployment rather than the Pod is the part of the answer that is about Kubernetes and not about Linux. A Pod owned by a ReplicaSet is a symptom. Scaling to zero and deleting the Deployment both stop the workload; deleting the Pod does not, and a verifier that runs a few seconds later sees the replacement.

## Verify

```bash
cat /opt/course/43/pod.txt                  # strace-lab/worker-a-...
kubectl get deploy -n strace-lab            # only worker-b
kubectl get pods  -n strace-lab             # one Running worker-b pod
kubectl get deploy worker-b -n strace-lab -o jsonpath='{.status.readyReplicas}'   # 1
```

## Docs

**Allowed:** `https://kubernetes.io/docs/tasks/debug/debug-cluster/crictl/` is the page to open in the exam. It carries the `crictl ps`, `crictl pods` and `crictl inspect` usage, including the go-template form used here. The Falco documentation at `https://falco.org/docs/` is allowed as well and covers the automated version of the same investigation.

`strace` has no Kubernetes page; `man strace` on the node is the reference. Worth memorising: `crictl ps`, `crictl pods --id <pod-id>`, `crictl inspect --output go-template --template '{{.info.pid}}' <container-id>`, and `strace -p <pid> -f -e trace=<syscall> -o <file>`.
