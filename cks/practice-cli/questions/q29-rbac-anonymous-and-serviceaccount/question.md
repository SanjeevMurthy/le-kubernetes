# Q29. Remove anonymous access and scope the ServiceAccount

An audit of this cluster turned up two RBAC findings.

1. A ClusterRoleBinding grants the built-in user `system:anonymous` the `view` ClusterRole, so anyone who can reach the API server without credentials can read the whole cluster. Find it and remove it. When you are done, no ClusterRoleBinding anywhere in the cluster may have `system:anonymous` as a subject.

2. ServiceAccount `reporter` in namespace `rbac-lab` is bound to `cluster-admin`. It is a reporting job and needs far less. Remove that binding and grant it exactly this instead, scoped to namespace `rbac-lab` only:

   - `get` and `list` on `pods`
   - `get` and `list` on `services`

   Afterwards `reporter` must be able to get Pods and list Services in `rbac-lab`, and must **not** be able to delete Pods or get Nodes.

Do not create a ClusterRole or a ClusterRoleBinding for `reporter`.
