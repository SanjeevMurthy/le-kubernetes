# Q24. Block the cloud metadata endpoint (solution)

## Steps

**1. Look at what is there.**

```bash
kubectl -n metadata-lab get pods --show-labels
kubectl -n metadata-lab get networkpolicy
```

**2. Write the policy.**

```bash
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: metadata-deny
  namespace: metadata-lab
spec:
  podSelector:
    matchLabels:
      app: app
  policyTypes:
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 169.254.169.254/32
EOF
```

**3. Check the object came out the way it was meant to.**

```bash
kubectl -n metadata-lab describe networkpolicy metadata-deny
kubectl -n metadata-lab get networkpolicy metadata-deny -o yaml
```

**4. Check the pods still work.**

```bash
kubectl -n metadata-lab get pods
kubectl -n metadata-lab run np-check --rm -it --restart=Never \
  --image=busybox:1.36 --labels=app=app -- nslookup kubernetes.default.svc.cluster.local
```

That probe carries the same label as the workload, so the policy applies to it. DNS resolving from it is the proof that the policy allows ordinary traffic. The metadata address itself times out:

```bash
kubectl -n metadata-lab run np-check --rm -it --restart=Never \
  --image=busybox:1.36 --labels=app=app -- wget -T 3 -O- http://169.254.169.254/
```

**5. If a question asks for the whole namespace instead of one workload**, the policy is identical with an empty `podSelector`:

```yaml
  podSelector: {}
```

## Why

A NetworkPolicy has no deny rule. Selecting a pod and naming a `policyType` denies that whole direction, and the rules listed under it are the only exceptions. That is why this task is written as one broad allow with a hole in it rather than as a block rule. `cidr: 0.0.0.0/0` restores everything the `Egress` policy type just took away, and `except: [169.254.169.254/32]` carves the metadata address back out of that allowance.

The order of evaluation is what makes `except` work. Within one `ipBlock`, `except` is subtracted from `cidr`, so the resulting allow-list is every address other than the excepted ones. Putting the metadata address in a separate rule would do nothing at all, because rules are additive and there is no rule type that removes an address another rule allowed.

`169.254.169.254` matters because it is the link-local address that AWS, GCP, Azure and others serve instance metadata on, including short-lived credentials for the node's own identity. Any pod that can reach it inherits the node's cloud permissions, which is a straight path from a compromised container to the cloud account. The address is link-local, so it is not routed and no firewall between the nodes ever sees the request. A NetworkPolicy on the pod is where it has to be stopped.

One detail that decides whether this works at all: `ipBlock` matches the destination IP after the CNI has done its work, and policies are enforced by the CNI rather than by Kubernetes. A cluster whose CNI does not implement NetworkPolicy accepts this object without complaint and enforces nothing, which is why the question is gated on Calico or Cilium being present.

## Verify

```bash
kubectl -n metadata-lab get networkpolicy metadata-deny \
  -o jsonpath='{.spec.policyTypes[*]}{"\n"}'
kubectl -n metadata-lab get networkpolicy metadata-deny \
  -o jsonpath='{.spec.podSelector.matchLabels.app}{"\n"}'
kubectl -n metadata-lab get networkpolicy metadata-deny \
  -o jsonpath='{.spec.egress[*].to[*].ipBlock.cidr}{"\n"}'
kubectl -n metadata-lab get networkpolicy metadata-deny \
  -o jsonpath='{.spec.egress[*].to[*].ipBlock.except[*]}{"\n"}'
kubectl -n metadata-lab get pods
```

## Docs

**Allowed:** `https://kubernetes.io/docs/concepts/services-networking/network-policies/`. The section headed "Targeting a range of ports" is not the one you want; scroll to the `ipBlock` example, which shows `cidr` with `except` in exactly the shape this answer needs. Copying that block and changing the two addresses is faster than writing it out.

The same page also carries the "Default policies" snippets, which are worth knowing by sight because a default-deny is asked for so often.
