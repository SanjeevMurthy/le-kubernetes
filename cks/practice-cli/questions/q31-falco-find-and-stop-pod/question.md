# Q31. Falco: identify the offending pod and stop it

**Host:** the worker node named in the setup output (root shell: `sudo -i`).

Falco is running on that worker. Namespace `falco-hunt` holds two Deployments scheduled there, `inventory` and `catalog`. One of them keeps reading a sensitive file, which trips the shipped rule **Read sensitive file untrusted**. The other one is an ordinary web server and is doing nothing wrong.

Falco names a container, not a Pod. Start at the alert and work back to Kubernetes.

1. Identify the Pod behind the alerts and write its `<namespace>/<pod-name>` to `/opt/course/31/offender.txt` (or `$COURSE_DIR/31/offender.txt` on this lab), on a single line and with nothing else in the file.

2. Stop that workload by scaling its Deployment to `0` replicas. Do not delete the Deployment, and do not delete the namespace.

3. Leave the innocent Deployment running with `1` replica, and leave the Falco service running.

Scaling both Deployments to zero is not a solution. The graded facts are that you named the right Pod and that you stopped only that one.
