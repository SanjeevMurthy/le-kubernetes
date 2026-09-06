# Q28. Run a Pod under gVisor and capture dmesg (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. Confirm the handler exists before writing anything.** A `RuntimeClass` naming a handler containerd does not know produces a Pod stuck in `ContainerCreating` with `RunContainerError`, and the cause is on the node, not in the manifest.

```bash
ssh <worker>
runsc --version
grep -A2 'runtimes.runsc' /etc/containerd/config.toml
exit
```

The handler name in the config is the string after `runtimes.` in
`[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]`, which is what `handler:` must match.

**2. Create the RuntimeClass.** It is cluster-scoped, so no namespace.

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc
EOF
```

**3. Create the Pod.** `runtimeClassName` goes at the Pod spec level, not in the container. Pin it to the worker, because that is the only node where `runsc` is installed.

```bash
W=$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o name | head -1 | cut -d/ -f2)
echo "$W"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: gvisor-test
  namespace: gvisor-lab
spec:
  runtimeClassName: gvisor
  nodeName: $W
  containers:
    - name: web
      image: nginx:1.27
EOF

kubectl -n gvisor-lab get pod gvisor-test -w
```

`kubectl run gvisor-test --image=nginx:1.27 -n gvisor-lab --dry-run=client -o yaml > pod.yaml` and then editing in the two fields is faster than typing the whole manifest.

**4. Capture the proof.**

```bash
mkdir -p /opt/course/28
kubectl exec -n gvisor-lab gvisor-test -- dmesg > /opt/course/28/dmesg.txt
head -3 /opt/course/28/dmesg.txt
```

The first lines read:

```
[    0.000000] Starting gVisor...
```

## Why

`dmesg` is the whole point of the task. A Pod spec can name any `runtimeClassName` and still be scheduled somewhere that silently runs it on the host runtime, or the field can be quietly dropped by a mutating webhook. The Pod's YAML therefore proves intent, never effect.

Inside a normal container `dmesg` reads the host's kernel ring buffer, so it either prints host kernel messages or is refused outright because `CAP_SYSLOG` is missing and `kernel.dmesg_restrict` is set. Under gVisor there is no host ring buffer to read. The Sentry, gVisor's user-space kernel, serves a ring buffer of its own, and it opens with `Starting gVisor...`. That banner cannot be produced by anything else, which is why it is the accepted evidence.

`runsc` intercepts system calls in user space and re-implements them, so a kernel exploit in the container reaches the Sentry rather than the host kernel. The cost is compatibility and speed, which is why gVisor is applied per workload through a `RuntimeClass` rather than turned on for the whole node.

The node pinning matters because a `RuntimeClass` says nothing about where the handler exists. In production you attach `scheduling.nodeSelector` to the RuntimeClass so the scheduler only places sandboxed Pods on nodes that have `runsc`; in the exam, `nodeName` is quicker.

## Verify

```bash
kubectl get runtimeclass gvisor -o jsonpath='{.handler}'; echo      # runsc
kubectl -n gvisor-lab get pod gvisor-test -o wide                   # Running, on the worker
kubectl -n gvisor-lab get pod gvisor-test -o jsonpath='{.spec.runtimeClassName}'; echo
kubectl exec -n gvisor-lab gvisor-test -- dmesg | head -3
grep -i gvisor /opt/course/28/dmesg.txt
```

## Docs

**Allowed:** `https://kubernetes.io/docs/concepts/containers/runtime-class/` has the RuntimeClass manifest and the `runtimeClassName` field, which is all you need to copy.

Worth memorising: `apiVersion: node.k8s.io/v1`, `handler:` matches the containerd runtime name, `runtimeClassName` sits on the Pod spec, and `dmesg` inside the Pod is the proof.
