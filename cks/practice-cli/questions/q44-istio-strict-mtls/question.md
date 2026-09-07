# Q44. Istio: enforce STRICT mTLS in a namespace

**Host:** any host with `kubectl` against a cluster running Istio.

Namespace `mesh-lab` has sidecar injection enabled and runs Deployment and Service `httpbin` on port 80. Namespace `mesh-out` has no injection at all, and the Pod `curl` in it has no sidecar.

Right now the mesh accepts both mutual TLS and plain text, which Istio calls `PERMISSIVE`. That means the Pod in `mesh-out` can reach the service in the mesh over plain HTTP:

```
kubectl exec -n mesh-out curl -c curl -- curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://httpbin.mesh-lab/get
200
```

1. Make every workload in `mesh-lab` accept mutual TLS only. Do it for the whole namespace with a single `PeerAuthentication` in `mesh-lab`, not per workload.

2. After the change, that same request from `mesh-out` must no longer return `200`.

3. Traffic inside the mesh must keep working. The Pod `mesh-client` in `mesh-lab` has a sidecar, and this must still return `200`:

   ```
   kubectl exec -n mesh-lab mesh-client -c client -- curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://httpbin.mesh-lab/get
   ```

Do not solve it with a NetworkPolicy, and do not change the `httpbin` Deployment or Service.
