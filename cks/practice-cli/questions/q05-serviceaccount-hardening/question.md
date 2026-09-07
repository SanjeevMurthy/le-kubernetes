# Q5. ServiceAccount Token Hardening

Pod `legacy` in namespace `app` runs `busybox:1.36` with the command `sleep 3600` as the `default` ServiceAccount, and has an API token mounted at `/var/run/secrets/kubernetes.io/serviceaccount`. The workload never calls the API server.

1. Create a ServiceAccount named `app-sa` in namespace `app` with automounting of its token disabled.
2. Make pod `legacy` run as `app-sa` with no ServiceAccount token mounted at all. Keep the image `busybox:1.36` and the command `sleep 3600`; `serviceAccountName` is immutable, so recreate the pod.
3. The pod must be Running when you are done, and `/var/run/secrets/kubernetes.io/serviceaccount` must no longer exist inside the container.
