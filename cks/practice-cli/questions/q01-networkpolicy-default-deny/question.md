# Q1. NetworkPolicy: Default-Deny + Selective Allow

Namespace `prod` runs a `backend` deployment (label `app=backend`) and a `frontend` deployment (label `app=frontend`). Apply a default-deny policy for all ingress and egress in `prod`, then add policies so that: (a) `backend` pods accept ingress only from `frontend` pods on TCP 8080, and (b) all pods may still resolve DNS. Do not break DNS.
