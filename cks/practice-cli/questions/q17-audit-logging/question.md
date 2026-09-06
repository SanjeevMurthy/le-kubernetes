# Q17. API Server Audit Logging Policy

Configure API server auditing: log Secret access at `RequestResponse`, drop read-only (`get`/`list`/`watch`) noise, and log everything else at `Metadata`. Write logs to `/var/log/kubernetes/audit.log`. Confirm the log is being written.
