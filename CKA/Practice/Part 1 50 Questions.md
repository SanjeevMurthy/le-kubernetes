| Domain                                                  | Frequency (Weight)        | Difficulty  | Typical Task Example                                                                                                                                 | Notes (common pitfalls)                                                                                                                                            |
| ------------------------------------------------------- | ------------------------- | ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Cluster Architecture / Installation & Configuration** | High (25%)                | Medium-High | Initialize cluster with kubeadm and CNI; configure RBAC (e.g. create ClusterRoleBinding for user).                                                   | Involves cluster setup/upgrades, HA control plane, etcd backup/restore. Source: CNCF blueprint.                                                                    |
| **Workloads & Scheduling**                              | Medium (15%)              | Medium      | Deployments, StatefulSets, DaemonSets. *Example:* Create a DaemonSet “logger” (busybox) running on all nodes.                                        | Covers Deployments (rolling updates/rollbacks), Jobs/CronJobs, ConfigMaps/Secrets, Pod affinity/taints, HPA.                                                       |
| **Services & Networking**                               | Medium (20%)              | Medium      | ClusterIP/NodePort services, Ingress, NetworkPolicy. *Example:* Create a ClusterIP service for a deployment and a NetworkPolicy to restrict traffic. | Includes DNS (CoreDNS), service types (ClusterIP/NodePort), and policy rules. Common pitfalls: wrong label selectors, forgetting to open firewall ports.           |
| **Storage**                                             | Low (10%)                 | Medium      | PersistentVolumes and Claims. *Example:* Create a PV and PVC (hostPath, 1Gi, RWX) and mount it in a Pod.                                             | Involves StorageClasses, dynamic provisioning. Common issues: incorrect access modes or storage class, forgetting to apply YAML.                                   |
| **Security (AuthN/AuthZ, RBAC)**                        | Moderate (cluster subset) | High        | Role/RoleBinding and ServiceAccounts. *Example:* Create a user certificate and RoleBinding to give “charlie” view rights.                            | Covers user auth (certs, tokens), RBAC, PodSecurity (Admission), NetworkPolicy. Must carefully set namespaces/contexts. Reliability: official and Red Hat sources. |
| **Troubleshooting**                                     | Highest (30%)             | High        | Debugging tasks (logs/events). *Example:* Identify and fix a CrashLoopBackOff by updating the Deployment’s image.                                    | Emphasized in exam. Tasks include checking `kubectl describe`, `kubectl logs`, events. Watch for exam UI delays (users report UI hangs).                           |



[Part 2: 50 Practice Questions]

1. Initialize a new Kubernetes cluster with kubeadm on the control-plane node (include a Pod network CNI, e.g. Flannel).  
2. Join a worker node to the cluster using the kubeadm join command.  
3. Perform a Kubernetes version upgrade (e.g. upgrade control-plane from 1.28 to 1.29) with kubeadm.  
4. Take an etcd snapshot backup of the control plane and then restore the cluster from that snapshot.  
5. Generate a CertificateSigningRequest for a new user “alice”, approve it, and update your kubectl config to use “alice”’s credentials.  
6. Create a ClusterRoleBinding that grants cluster-admin privileges to user “bob”.  
7. Use Helm to install an NGINX Ingress controller into the cluster.  
8. Use Kustomize to apply a CustomResourceDefinition or an operator manifest.  
9. Create a new namespace dev and switch your context to that namespace.  
10. Deploy a Deployment named “webserver” with 3 replicas of the image nginx:latest in namespace dev.  
11. Update the “webserver” Deployment to use image nginx:1.21 (simulate a rolling update).  
12. Roll back the “webserver” Deployment to its previous image version.  
13. Scale the “webserver” Deployment up to 5 replicas.  
14. Create a ConfigMap app-config (with at least one key-value pair) and mount it into a new Pod in dev as an environment variable.  
15. Create a Secret db-secret (with database credentials) and mount it as a volume in a new Pod in dev.  
16. Create a DaemonSet “logger” in the default namespace using the busybox image that runs a simple shell loop on every node.  
17. Deploy a Job named “cleanup” in namespace dev that runs a one-time task (e.g. a busybox container that prints “Cleanup” and exits).  
18. Deploy a CronJob named “backup” in namespace dev that prints “Backup!” once every minute.  
19. Taint all worker nodes with a key example=demo:NoSchedule, then create a Pod in dev that includes a toleration so it can schedule on a tainted node.  
20. Add a node label (e.g. zone=west) to one node and use nodeAffinity in a Pod spec to ensure the Pod runs on that node.  
21. Add CPU and memory resource requests and limits to the containers of the “webserver” Deployment.  
22. Use an imperative command (e.g. kubectl run) to create a Pod named “test-pod” in namespace dev with image busybox that sleeps for 300 seconds.  
23. Create a ClusterIP Service named “web-svc” in namespace dev that exposes port 80 of the “webserver” Deployment pods.  
24. Change the Service “web-svc” to type NodePort and set its nodePort to 30080 so it is accessible externally.  
25. Create namespaces frontend and backend; deploy a Pod labeled role=frontend in frontend and a Pod labeled app=backend in backend. Then create a NetworkPolicy in backend that only allows ingress traffic from pods in namespace frontend.  
26. In namespace dev, create a NetworkPolicy that denies all ingress traffic to pods labeled app=web.  
27. Create an Ingress resource (assume an ingress controller is installed) that routes host example.com to the “web-svc” Service on port 80.  
28. Launch a temporary busybox Pod (e.g. kubectl run busybox --image=busybox -i --tty) and inside it execute nslookup kubernetes.default.svc.cluster.local to verify DNS resolution within the cluster.  
29. From a Pod in namespace dev (e.g. using kubectl exec into a curl-capable container), curl the “web-svc” Service’s cluster IP or DNS name to test connectivity.  
30. Create a PersistentVolume named data-volume (using hostPath /data on the node) with capacity 1Gi and access mode ReadWriteMany.  
31. Create a PersistentVolumeClaim named data-pvc in namespace dev that requests 1Gi with access mode ReadWriteMany, binding it to data-volume.  
32. Deploy a Pod “data-app” in namespace dev using nginx:latest that mounts the data-pvc volume at /var/data.  
33. (If metrics-server is enabled) Run kubectl top nodes and kubectl top pods to display current CPU/memory usage in the cluster.  
34. Create a ServiceAccount named “builder” in namespace dev and bind it to the edit role using a RoleBinding.  
35. Configure a static Pod named “static-web” on the control plane node running nginx.  
36. Drain a worker node for maintenance and uncordon it after completion.  
37. Create a HorizontalPodAutoscaler for the “webserver” Deployment with min 2 and max 6 replicas, targeting 70% CPU utilization.  
38. Create a StatefulSet named “mysql” with 2 replicas using the mysql:5.7 image and a PersistentVolumeClaim template.  
39. Configure liveness and readiness probes on the “webserver” Deployment containers.  
40. Expose the “mysql” StatefulSet via a Headless Service for stable DNS resolution.  
41. Create and apply a PodDisruptionBudget for “webserver” ensuring at least one pod remains available.  
42. Add an annotation to the “webserver” Deployment with key purpose=demo.  
43. Create a Pod with multiple containers (nginx and busybox) sharing a volume via emptyDir.  
44. Configure an initContainer in the “webserver” Deployment to echo “Init complete” before starting nginx.  
45. Create a PodSecurityPolicy (if enabled) that restricts running privileged containers.  
46. Use kubectl explain to view field definitions for Deployment.spec.replicas.  
47. Use kubectl describe node to view allocated resources and conditions.  
48. View logs of a crashed Pod using kubectl logs --previous.  
49. Debug a Pod by creating an ephemeral debug container using kubectl debug.  
50. Export all resources in namespace dev to YAML files using kubectl get all -n dev -o yaml > dev-backup.yaml.
