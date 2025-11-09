| Domain                                                  | Frequency (Weight)        | Difficulty  | Typical Task Example                                                                                                                                 | Notes (common pitfalls)                                                                                                                                            |
| ------------------------------------------------------- | ------------------------- | ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Cluster Architecture / Installation & Configuration** | High (25%)                | Medium-High | Initialize cluster with kubeadm and CNI; configure RBAC (e.g. create ClusterRoleBinding for user).                                                   | Involves cluster setup/upgrades, HA control plane, etcd backup/restore. Source: CNCF blueprint.                                                                    |
| **Workloads & Scheduling**                              | Medium (15%)              | Medium      | Deployments, StatefulSets, DaemonSets. *Example:* Create a DaemonSet “logger” (busybox) running on all nodes.                                        | Covers Deployments (rolling updates/rollbacks), Jobs/CronJobs, ConfigMaps/Secrets, Pod affinity/taints, HPA.                                                       |
| **Services & Networking**                               | Medium (20%)              | Medium      | ClusterIP/NodePort services, Ingress, NetworkPolicy. *Example:* Create a ClusterIP service for a deployment and a NetworkPolicy to restrict traffic. | Includes DNS (CoreDNS), service types (ClusterIP/NodePort), and policy rules. Common pitfalls: wrong label selectors, forgetting to open firewall ports.           |
| **Storage**                                             | Low (10%)                 | Medium      | PersistentVolumes and Claims. *Example:* Create a PV and PVC (hostPath, 1Gi, RWX) and mount it in a Pod.                                             | Involves StorageClasses, dynamic provisioning. Common issues: incorrect access modes or storage class, forgetting to apply YAML.                                   |
| **Security (AuthN/AuthZ, RBAC)**                        | Moderate (cluster subset) | High        | Role/RoleBinding and ServiceAccounts. *Example:* Create a user certificate and RoleBinding to give “charlie” view rights.                            | Covers user auth (certs, tokens), RBAC, PodSecurity (Admission), NetworkPolicy. Must carefully set namespaces/contexts. Reliability: official and Red Hat sources. |
| **Troubleshooting**                                     | Highest (30%)             | High        | Debugging tasks (logs/events). *Example:* Identify and fix a CrashLoopBackOff by updating the Deployment’s image.                                    | Emphasized in exam. Tasks include checking `kubectl describe`, `kubectl logs`, events. Watch for exam UI delays (users report UI hangs).                           |



[Part 2: 50 Practice Questions]

Initialize a new Kubernetes cluster with kubeadm on the control-plane node (include a Pod network CNI, e.g. Flannel).
Join a worker node to the cluster using the kubeadm join command.

Perform a Kubernetes version upgrade (e.g. upgrade control-plane from 1.28 to 1.29) with kubeadm.

Take an etcd snapshot backup of the control plane and then restore the cluster from that snapshot.

Generate a CertificateSigningRequest for a new user “alice”, approve it, and update your kubectl config to use “alice”’s credentials.

Create a ClusterRoleBinding that grants cluster-admin privileges to user “bob”.

Use Helm to install an NGINX Ingress controller into the cluster.

Use Kustomize to apply a CustomResourceDefinition or an operator manifest.

Create a new namespace dev and switch your context to that namespace.

Deploy a Deployment named “webserver” with 3 replicas of the image nginx:latest in namespace dev.

Update the “webserver” Deployment to use image nginx:1.21 (simulate a rolling update).

Roll back the “webserver” Deployment to its previous image version.

Scale the “webserver” Deployment up to 5 replicas.

Create a ConfigMap app-config (with at least one key-value pair) and mount it into a new Pod in dev as an environment variable.

Create a Secret db-secret (with database credentials) and mount it as a volume in a new Pod in dev.

Create a DaemonSet “logger” in the default namespace using the busybox image that runs a simple shell loop on every node
go-cloud-native.com
.

Deploy a Job named “cleanup” in namespace dev that runs a one-time task (e.g. a busybox container that prints “Cleanup” and exits).

Deploy a CronJob named “backup” in namespace dev that prints “Backup!” once every minute.

Taint all worker nodes with a key example=demo:NoSchedule, then create a Pod in dev that includes a toleration so it can schedule on a tainted node.

Add a node label (e.g. zone=west) to one node and use nodeAffinity in a Pod spec to ensure the Pod runs on that node.

Add CPU and memory resource requests and limits to the containers of the “webserver” Deployment.

Use an imperative command (e.g. kubectl run) to create a Pod named “test-pod” in namespace dev with image busybox that sleeps for 300 seconds.

Create a ClusterIP Service named “web-svc” in namespace dev that exposes port 80 of the “webserver” Deployment pods.

Change the Service “web-svc” to type NodePort and set its nodePort to 30080 so it is accessible externally.

Create namespaces frontend and backend; deploy a Pod labeled role=frontend in frontend and a Pod labeled app=backend in backend. Then create a NetworkPolicy in backend that only allows ingress traffic from pods in namespace frontend
medium.com
.

In namespace dev, create a NetworkPolicy that denies all ingress traffic to pods labeled app=web.

Create an Ingress resource (assume an ingress controller is installed) that routes host example.com to the “web-svc” Service on port 80.

Launch a temporary busybox Pod (e.g. kubectl run busybox --image=busybox -i -- tty) and inside it execute nslookup kubernetes.default.svc.cluster.local to verify DNS resolution within the cluster.

From a Pod in namespace dev (e.g. using kubectl exec into a curl-capable container), curl the “web-svc” Service’s cluster IP or DNS name to test connectivity.

Create a PersistentVolume named data-volume (using hostPath /data on the node) with capacity 1Gi and access mode ReadWriteMany.

Create a PersistentVolumeClaim named data-pvc in namespace dev that requests 1Gi with access mode ReadWriteMany, binding it to data-volume.

Deploy a Pod “data-app” in namespace dev using nginx:latest that mounts the data-pvc volume at /var/data.

In namespace dev, create a ServiceAccount app-sa; then create a Role allowing get,list on pods and bind that Role to app-sa via a RoleBinding.

Create a CSR (CertificateSigningRequest) named charlie-csr for user “charlie”, approve it, retrieve the signed cert, and configure your kubeconfig to use the new “charlie” user.

In namespace default, create a RoleBinding that grants user “alice” the built-in “view” ClusterRole (read-only access to pods).

A Deployment “legacy-app” is CrashLoopBackOff due to a typo in its image. Use kubectl describe or logs to identify the problem, then fix the Deployment’s image name.

Describe the Deployment named “batch-job” that has failed rollout, identify the error in events, and correct the issue so it starts successfully.

The CoreDNS pods in kube-system are CrashLoopBackOff. Edit the CoreDNS ConfigMap to fix any typo or misconfiguration, then rollout restart the CoreDNS pods.

One node shows a DiskPressure taint. Remove the taint (kubectl taint nodes node1 node.kubernetes.io/disk-pressure-) so pods can schedule again.

In namespace dev, create a NetworkPolicy to allow traffic to the “webserver” pods from pods in namespace frontend (reverse direction of the pods from Q25).

A Service “db-svc” in namespace dev has no endpoints. Fix it by correcting the pod label so it matches the service’s selector.

Cordon one node (kubectl cordon) and then drain it (kubectl drain) to move its pods to other nodes. Afterwards, kubectl uncordon the node.

A Pod “orphan” is stuck terminating. Force delete it using kubectl delete pod orphan --grace-period=0 --force.

Use kubectl logs to fetch the logs from a failing Pod “my-app” in namespace dev and identify the error message.

Run kubectl get events --all-namespaces to list recent events; explain how inspecting events can help troubleshoot scheduling or resource issues.

Create a ResourceQuota in namespace dev that limits Pods to 2 and total memory requests to 2Gi.

Label node “worker1” with env=prod, then create a Pod with nodeSelector: env=prod so it schedules on that node.

Deploy a StatefulSet named “mysql” with 2 replicas in namespace dev, using a PVC template (“mysql-pv-%d”) for each replica.

Delete one of the Pods in the “webserver” Deployment; observe that the ReplicaSet recreates it (testing self-healing).

(If metrics-server is enabled) Run kubectl top nodes and kubectl top pods to display current CPU/memory usage in the cluster.
