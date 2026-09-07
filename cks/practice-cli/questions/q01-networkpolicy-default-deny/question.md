# Q1. NetworkPolicy: Default-Deny + Selective Allow

Namespace `netpol-lab` runs a `backend` deployment (label `app=backend`, container port 8080) and a `frontend` deployment (label `app=frontend`). There are no NetworkPolicies in the namespace yet.

1. Apply a default-deny policy for all ingress and egress traffic in `netpol-lab`.
2. Add a policy so that `backend` pods accept ingress only from `frontend` pods, on TCP 8080.
3. Add a policy so that every pod in `netpol-lab` can still resolve DNS.

Both deployments must still be Running, and `nslookup kubernetes.default.svc.cluster.local` from a pod in `netpol-lab` must still succeed.
