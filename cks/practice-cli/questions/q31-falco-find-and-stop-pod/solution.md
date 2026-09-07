# Q31. Falco: identify the offending pod and stop it (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

Everything happens on the worker node, as root.

```bash
ssh <worker>
sudo -i
```

**1. Read the alerts.** Falco logs to the journal of whichever unit is running. Ask for both, so it does not matter which one this node uses.

```bash
journalctl -u falco-modern-bpf -u falco --since '-3 min' --no-pager \
  | grep 'Read sensitive file untrusted' | tail -5
```

Each line carries `container_id=<12 hex chars>` and `container_name=<name>`. That is the only identity Falco gives you by default, because the Kubernetes metadata collector is not enabled in a stock install.

**2. Take one container ID.**

```bash
CID=$(journalctl -u falco-modern-bpf -u falco --since '-3 min' --no-pager \
  | grep 'Read sensitive file untrusted' \
  | grep -oE 'container_id=[0-9a-f]+' | tail -1 | cut -d= -f2)
echo "$CID"
```

**3. Map the container back to its Pod.** The container runtime records the Pod name and namespace as labels on the container.

```bash
crictl ps --id "$CID"
crictl inspect "$CID" | grep -E '"io.kubernetes.pod.name"|"io.kubernetes.pod.namespace"'
```

If `crictl` complains about the runtime endpoint, point it at containerd:

```bash
crictl --runtime-endpoint unix:///run/containerd/containerd.sock ps --id "$CID"
```

**4. Confirm from the API side.** The Pod name from step 3 must appear in `falco-hunt`.

```bash
kubectl get pods -n falco-hunt -o wide
```

**5. Write the deliverable.**

```bash
mkdir -p /opt/course/31
kubectl get pods -n falco-hunt -o wide
echo "falco-hunt/<pod-name-from-step-3>" > /opt/course/31/offender.txt
cat /opt/course/31/offender.txt
```

**6. Stop only that workload.** The Pod belongs to a Deployment, so deleting the Pod would bring an identical one straight back. Scale the Deployment instead.

```bash
kubectl get pod -n falco-hunt <pod-name> -o jsonpath='{.metadata.ownerReferences[0].name}'   # the ReplicaSet
kubectl scale deploy inventory -n falco-hunt --replicas=0
kubectl get deploy,pods -n falco-hunt
```

`catalog` must still show `1/1`.

## Why

Falco watches syscalls, so it sees a process inside a container and knows nothing about Deployments or Services. The identity it emits is the container ID from the runtime. Every incident that starts with a Falco alert therefore has the same first move: container ID, then `crictl inspect`, then the Pod, then the controller that owns it.

The reason to scale the Deployment rather than delete the Pod is the reason Deployments exist. A ReplicaSet recreates a deleted Pod within seconds, the alert returns, and the responder looks as if they did nothing. Scaling to zero changes the desired state, which is what actually stops the workload.

The reason not to touch `catalog` is that a real cluster is a shared cluster. Stopping everything in the namespace ends the alert and also ends the service the business is running, which converts a contained incident into an outage. Precision is the graded skill here, not speed.

Leaving Falco running matters for the same reason. A responder who stops the detector to stop the noise has removed the only evidence that the next attempt is happening.

## Verify

```bash
cat /opt/course/31/offender.txt              # falco-hunt/inventory-<hash>
kubectl get deploy -n falco-hunt             # inventory 0/0, catalog 1/1
kubectl get pods -n falco-hunt               # only the catalog pod
systemctl is-active falco-modern-bpf || systemctl is-active falco
```

## Docs

**Allowed:** `https://falco.org/docs/` for the rule and the output fields.

`crictl` is not in the allowed documentation set, so `crictl --help`, `crictl ps --help` and `crictl inspect <id>` on the node are the reference. Memorise the shape: `crictl ps --id <container-id>` and `crictl inspect <container-id>` with a `grep` for `io.kubernetes.pod.name`.
