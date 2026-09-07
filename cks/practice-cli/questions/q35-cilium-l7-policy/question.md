# Q35. CiliumNetworkPolicy: allow only GET /health

**Host:** the cluster you are already on. No node access is needed.

This cluster runs Cilium as its CNI. Namespace `cilium-lab` holds two workloads:

- Deployment `api`, pod label `app=api`, exposed by Service `api` on TCP port 80. It answers `GET /health` with `200` and every other path with `404`.
- Deployment `client`, pod label `app=client`, which has `curl` in it.

There is no policy in the namespace, so `client` can currently call every path on `api`.

1. Create a `CiliumNetworkPolicy` in namespace `cilium-lab` that applies to the `api` pods and to those pods only.

2. It must allow ingress from the `client` pods only, on TCP port `80`, and only the HTTP request `GET /health`.

3. Every other request from `client` to `api` must come back as **`403`**, not as a timeout. A Layer 3 or Layer 4 rejection silently drops the packet and the client hangs until it gives up. A Layer 7 rejection is produced by the Cilium proxy, which answers with an HTTP status code. That difference is what this question is about.

Check it from inside the client pod:

```bash
kubectl exec -n cilium-lab deploy/client -- curl -s -o /dev/null -w '%{http_code}\n' http://api/health
kubectl exec -n cilium-lab deploy/client -- curl -s -o /dev/null -w '%{http_code}\n' http://api/anything
```

The first must print `200` and the second must print `403`.
