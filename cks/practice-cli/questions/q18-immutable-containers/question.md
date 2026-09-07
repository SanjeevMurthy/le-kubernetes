# Q18. Immutable Containers (readOnlyRootFilesystem)

Deployment `api` in namespace `immutable-lab` runs `nginx` with a writable root filesystem.

1. Harden the deployment so its container runs with a read-only root filesystem and cannot escalate privileges.
2. Keep the container able to write to `/tmp`, and give nginx the writable paths it needs to start (`/var/cache/nginx` and `/var/run`), using `emptyDir` volumes.
3. The pod must be Running when you are done, `touch /tmp/probe` inside the container must succeed, and `touch /etc/probe` must fail.
