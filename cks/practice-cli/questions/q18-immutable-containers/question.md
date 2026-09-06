# Q18. Immutable Containers (readOnlyRootFilesystem)

Harden deployment `api` in namespace `prod` so its container runs with a read-only root filesystem and cannot escalate privileges, while still being able to write to `/tmp`.
