# Q4. RBAC Least-Privilege Role + Binding

ServiceAccount `ci` in namespace `build` currently has cluster-admin via a binding. Replace it so `ci` can only `get`, `list`, and `watch` `pods` and `pods/log` in namespace `build` — nothing else. Verify the effective permissions.
