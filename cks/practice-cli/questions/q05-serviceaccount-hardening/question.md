# Q5. ServiceAccount Token Hardening

The pod `legacy` in namespace `app` should not have a ServiceAccount token mounted (it never calls the API). Create a dedicated ServiceAccount `app-sa` with automount disabled, and ensure the pod uses it with no token mounted.
