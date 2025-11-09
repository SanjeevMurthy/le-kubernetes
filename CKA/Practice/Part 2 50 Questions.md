# Domain I: Troubleshooting (30%) - The High-Stakes Domain

As the most heavily weighted domain, Troubleshooting presents the most complex and challenging scenarios. Success in this area is paramount to passing the exam.

**Core Task 1:** Control Plane Failure Diagnosis. A recurring, high-difficulty scenario involves diagnosing and repairing a non-functional control plane. The typical setup presents a cluster where key components like kube-apiserver and kube-scheduler are failing, while etcd and the kubelet remain operational. The task requires a systematic approach to debugging. Candidates must inspect the static pod manifests located in /etc/kubernetes/manifests, validate the YAML configuration files for errors, and examine component logs. Since these components run as static pods, standard kubectl logs commands will not work; proficiency with node-level tools like journalctl or container-runtime-specific commands (e.g., crictl logs) is essential.

**Core Task 2:** Worker Node & CNI Misconfiguration. This pattern tests the candidate's understanding of the networking stack at the node level. A common task involves installing a Container Network Interface (CNI) plugin, such as Calico or Flannel, from a provided manifest file. After installation, pods remain in a Pending or ContainerCreating state. The root cause is often a mismatch between the Pod CIDR range configured for the cluster via kubeadm and the network range defined in the CNI's configuration, which is typically stored in a ConfigMap or a Custom Resource. The candidate must identify this discrepancy and patch the CNI's configuration to align with the cluster's Pod CIDR, thereby restoring pod-to-pod connectivity. This directly assesses the "Troubleshoot clusters and nodes" competency outlined in the official curriculum.

**Core Task 3:** Application & Networking Debugging. These tasks present a functioning cluster but a failing application, often due to connectivity issues. Scenarios may involve debugging why a service is unreachable, which requires checking that the service's label selector correctly matches the pods' labels, verifying that the Endpoints object has been populated with pod IPs, and ensuring that no Network Policies are inadvertently blocking traffic. Another common variant involves troubleshooting DNS resolution failures, which points towards investigating the health and configuration of CoreDNS in the kube-system namespace.

# Domain II: Cluster Architecture, Installation & Configuration (25%) - The Modern Tooling Domain

This domain has been significantly updated to include modern application management and cluster extension tools.

**Core Task 1:** Helm Operations. Proficiency with the Helm CLI is now mandatory. A representative task involves installing a software package (e.g., ArgoCD) using a Helm chart from a public repository. A frequent and subtle variation of this task requires installing a chart while preventing the installation of its associated CRDs, under the premise that the CRDs already exist in the cluster from a previous installation. This requires knowledge of specific Helm flags like --skip-crds or chart-specific values passed via --set crds.install=false. Another reported task involves using helm template to render a chart's manifests into a local file for inspection or modification before applying them to the cluster with kubectl apply -f.

**Core Task 2:** CRD Management. This tests the ability to interact with and understand cluster API extensions. A typical two-part task involves first listing all CRDs in the cluster that match a certain keyword (e.g., cert-manager) and redirecting the output to a file. The second part requires the candidate to use the kubectl explain command to introspect the schema of one of these CRDs. For example, the task might be to find and document the purpose of a specific field, such as spec.secretName, within a Certificate CRD. This is a direct, practical test of the "Understand CRDs" competency.

**Core Task 3:** RBAC Configuration. A classic CKA task, Role-Based Access Control configuration remains a core competency. Exam questions typically present a scenario requiring the creation of a Role (for namespace-scoped permissions) or a ClusterRole (for cluster-wide permissions). The candidate must then create a RoleBinding or ClusterRoleBinding to grant a specific user or ServiceAccount the defined permissions. The permissions are usually very specific, such as granting the ability to only get, list, and watch pods within the frontend namespace.

# Domain III: Services & Networking (20%) - The Connectivity Domain

Networking questions on the CKA exam are known for their complexity and nuance, requiring careful reading and precise execution.

**Core Task 1:** Ingress to Gateway API Migration. This is a flagship task of the 2025 curriculum, reflecting the industry's shift towards the more expressive and role-oriented Gateway API. A common scenario involves an existing application that is exposed to external traffic via a traditional Ingress resource. The candidate's task is to create a new Gateway resource and an HTTPRoute resource to replicate the exact functionality of the old Ingress, including host-based routing and TLS termination using an existing secret. After verifying the new configuration works, the final step is to delete the legacy Ingress resource. This task directly assesses the "Use the Gateway API to manage Ingress traffic" competency.

**Core Task 2:** Advanced Network Policy Implementation. Network Policy questions have evolved beyond simple ingress denial. A frequent format presents a complex traffic flow requirement and provides several pre-written YAML manifests for different Network Policies. The candidate must analyze the requirement (e.g., "Allow ingress traffic to pods with label app=backend only from pods in the frontend namespace on TCP port 8080") and select and apply the one manifest that correctly implements this rule. Success requires a deep understanding of how podSelector, namespaceSelector, and ipBlock work together in both ingress and egress rules.

**Core Task 3:** Service Exposure. While fundamental, this task appears frequently and tests for precision under pressure. The objective is typically to expose an existing Deployment using a NodePort service. The question will specify the exact port on the node (nodePort), the port on the service, and the container's target port that traffic should be forwarded to.

# Domain IV: Workloads & Scheduling (15%) - The Resource Management Domain

This domain focuses on the lifecycle of applications running on the cluster and the mechanisms for controlling their placement and resource consumption.

**Core Task 1:** Node Resource Allocation. This is a highly practical task that simulates a real-world resource contention problem. The scenario involves a Deployment with multiple replicas where some pods are stuck in the Pending state due to insufficient CPU or memory on the worker nodes. The candidate must first use kubectl describe node <node-name> to inspect the node's Allocatable resources. Then, they must perform a calculation to determine how to distribute the available resources evenly among the required number of pods, ensuring to leave a small buffer for system daemons. Finally, they must edit the Deployment manifest to set appropriate CPU and memory requests and limits that allow all replicas to be scheduled successfully.

**Core Task 2:** Horizontal Pod Autoscaler (HPA) Configuration. This is a common task testing the "Configure workload autoscaling" competency. The candidate is asked to create a HorizontalPodAutoscaler for an existing Deployment. The requirements are specific: scale based on CPU utilization, with a defined minimum and maximum number of replicas (e.g., min 2, max 5), and a target average CPU utilization percentage across all pods (e.g., 70%).

**Core Task 3:** Default StorageClass Configuration. This is a subtle administrative task that can easily trip up candidates unfamiliar with annotations. The scenario presents a cluster with multiple StorageClass objects, none of which is designated as the default. The task is to make one of them the default for all future dynamic provisioning requests that do not specify a storageClassName. This cannot be achieved by simply editing the object's spec. The correct method is to use kubectl patch to set the annotation storageclass.kubernetes.io/is-default-class to "true" on the desired StorageClass. It is also best practice to ensure this annotation is set to "false" or is absent on all other StorageClasses.



# The CKA 2025 Practice Question Bank.
## This question bank is designed to reflect the "brownfield," scenario-based nature of the 2025 CKA exam. Each question requires analysis, modification, or troubleshooting of a pre-existing environment.

## Domain: Troubleshooting

## Question 1: Control Plane Component Failure

- **Scenario:** The cluster's API server is unresponsive. `kubectl` commands are failing with a connection refused error. The `etcd` and `kubelet` services on the control plane node `cp-node` are confirmed to be running.  
- **Initial State:** The static pod manifest for the kube-apiserver located at `/etc/kubernetes/manifests/kube-apiserver.yaml` on `cp-node` has been corrupted. A command argument is misspelled.  
- **Task:** SSH into `cp-node`. Investigate the kube-apiserver static pod manifest and correct the configuration error. Ensure the API server starts successfully and the cluster becomes responsive.  
- **Validation:** From the base node, run `kubectl get nodes`. The command should execute successfully and show the cluster nodes.  

---

## Question 2: CNI Pod CIDR Mismatch

- **Scenario:** A new worker node, `worker-3`, has been added to the cluster, but pods scheduled on it cannot communicate with pods on other nodes. Pods on `worker-3` are stuck in the `ContainerCreating` state.  
- **Initial State:** The cluster is using the Calico CNI. The main Calico configuration ConfigMap, named `calico-config` in the `kube-system` namespace, defines a Pod IP range that does not include the Pod CIDR assigned to `worker-3`.  
- **Task:** Identify the Pod CIDR assigned to `worker-3` by inspecting the node object. Edit the `calico-config` ConfigMap in the `kube-system` namespace to correctly include the Pod CIDR range of all nodes.  
- **Validation:** Create a test pod and ensure it gets scheduled on `worker-3` and enters the Running state. Exec into the pod and ping another pod on a different worker node.  

---

## Question 3: CoreDNS Configuration Error

- **Scenario:** Pods across the cluster are unable to resolve external domain names (e.g., `google.com`), although internal service name resolution is working.  
- **Initial State:** The `coredns` ConfigMap in the `kube-system` namespace has been modified, and the `forward` plugin, which points to upstream DNS servers, has been accidentally removed.  
- **Task:** Edit the `coredns` ConfigMap. Re-add the `forward` plugin to the Corefile configuration, pointing to a public DNS server like `8.8.8.8`. After saving the changes, restart the CoreDNS pods to apply the new configuration.  
- **Validation:** Exec into a busybox pod and run `nslookup google.com`. The command should succeed.  

---

## Question 4: Ingress Controller Pods Not Ready

- **Scenario:** The NGINX Ingress Controller pods in the `ingress-nginx` namespace are in a `CrashLoopBackOff` state. Ingress resources are not functioning.  
- **Initial State:** The `ingress-nginx-controller` Deployment has a misconfigured liveness probe with an incorrect port, causing the kubelet to repeatedly kill and restart the pods.  
- **Task:** Inspect the `ingress-nginx-controller` Deployment in the `ingress-nginx` namespace. Identify the incorrect port in the liveness probe configuration and correct it to match the health check port exposed by the controller (port `10254`).  
- **Validation:** Run `kubectl get pods -n ingress-nginx`. The controller pods should enter the Running state and remain stable.  

---

## Question 5: Node NotReady due to Kubelet Issue

- **Scenario:** A worker node named `node-fail` is reporting a `NotReady` status. Pods are being evicted from this node.  
- **Initial State:** The kubelet service on `node-fail` has stopped due to a configuration error in `/var/lib/kubelet/config.yaml` (e.g., an invalid `cgroupDriver` value).  
- **Task:** SSH into `node-fail`. Check the status of the kubelet service using `systemctl status kubelet`. Examine the service logs using `journalctl -u kubelet` to identify the configuration error. Correct the error in `/var/lib/kubelet/config.yaml` and restart the kubelet service.  
- **Validation:** From the control plane, run `kubectl get nodes`. The status of `node-fail` should return to `Ready`.  

---

## Question 6: Service Endpoint Failure

- **Scenario:** A service named `frontend-svc` in the `default` namespace exists, but it has no endpoints, even though there are running pods that should be part of the service.  
- **Initial State:** The `frontend-svc` Service has a selector `app=frontend-app`, but the corresponding Deployment's pods have the label `app=frontend-web`.  
- **Task:** Modify the selector of the `frontend-svc` Service to match the labels of the existing pods (`app=frontend-web`).  
- **Validation:** Run `kubectl describe service frontend-svc`. The Endpoints field should now be populated with the IP addresses of the running pods.  

---

## Question 7: Persistent Volume Claim Stuck in Pending

- **Scenario:** A developer has created a PersistentVolumeClaim named `db-pvc` that is stuck in the `Pending` state and will not bind.  
- **Initial State:** The `db-pvc` requests 5Gi of storage with the `standard` StorageClass. However, the `standard` StorageClass provisions volumes that use the `ReadWriteMany` access mode, while the PVC is requesting `ReadWriteOnce`.  
- **Task:** There are no PVs that can satisfy the claim. Edit the `db-pvc` PersistentVolumeClaim and change its requested `accessModes` from `ReadWriteOnce` to `ReadWriteMany` to match what the StorageClass provides.  
- **Validation:** Run `kubectl get pvc db-pvc`. The status should change from `Pending` to `Bound`.  

---

## Question 8: Job Failing to Complete

- **Scenario:** A Job named `data-processor` continuously creates new pods that fail, and the Job never completes.  
- **Initial State:** The pod template within the `data-processor` Job specifies a container image `my-app:latest` that does not exist in the registry. The pods fail with an `ImagePullBackOff` error.  
- **Task:** Inspect the logs of one of the failed pods created by the Job to identify the image pull error. Edit the `data-processor` Job and correct the container image name to a valid one, such as `busybox`.  
- **Validation:** Delete the failed pods. The Job should create a new pod that runs to completion. Verify by running `kubectl get jobs data-processor` and checking that `COMPLETIONS` is `1/1`.  

---

## Question 9: Misconfigured Network Policy Blocking Traffic

- **Scenario:** A web application in the `web` namespace cannot connect to its database in the `db` namespace.  
- **Initial State:** A default-deny ingress Network Policy is applied to the `db` namespace. An additional Network Policy exists that is intended to allow traffic from the `web` namespace, but its `namespaceSelector` is misconfigured.  
- **Task:** Examine the Network Policies in the `db` namespace. Identify the policy intended to allow ingress from `web` and correct its `namespaceSelector` to properly match the labels of the `web` namespace.  
- **Validation:** Exec into a pod in the `web` namespace and successfully connect to the database service in the `db` namespace using a tool like `curl` or `netcat`.  

---

## Question 10: Scheduler Failure

- **Scenario:** Newly created pods are remaining in the `Pending` state indefinitely. The cluster scheduler appears to be non-functional.  
- **Initial State:** The `kube-scheduler` static pod manifest at `/etc/kubernetes/manifests/kube-scheduler.yaml` on the control plane node references a non-existent configuration file via the `--config` flag.  
- **Task:** SSH to the control plane node. Inspect the `kube-scheduler` logs using `crictl logs` (or equivalent) to find the error about the missing config file. Edit the manifest at `/etc/kubernetes/manifests/kube-scheduler.yaml` and remove the invalid `--config` flag to allow the scheduler to start with its default configuration.  
- **Validation:** Create a new NGINX pod. It should be scheduled and transition to the Running state.  


## Domain: Cluster Architecture, Installation & Configuration (10 Questions)
## Question 11: Install a Component with Helm

- **Scenario:** The monitoring team requires Prometheus to be installed in the cluster to collect metrics.  
- **Initial State:** A namespace `monitoring` exists. Helm is installed.  
- **Task:** Add the `prometheus-community` Helm repository. Install the Prometheus chart from this repository into the `monitoring` namespace, giving it the release name `prom-stack`.  
- **Validation:** Run `helm list -n monitoring`. It should show the `prom-stack` release in a deployed status.  

---

## Question 12: Helm Install with Custom Values

- **Scenario:** An existing Helm installation of cert-manager needs to be configured to not install its CRDs, as they will be managed manually.  
- **Initial State:** The `jetstack` Helm repository has been added.  
- **Task:** Install the `cert-manager` chart from the `jetstack` repository into the `cert-manager` namespace. During installation, use the `--set` flag to set the `installCRDs` value to `false`.  
- **Validation:** Run `kubectl get crds | grep cert-manager`. No CRDs related to cert-manager should be present.  

---

## Question 13: List and Explain a CRD

- **Scenario:** An operator for Vault has been installed, and you need to document one of its custom resources.  
- **Initial State:** The cluster contains several CRDs, including `vaultsecrets.secrets.hashicorp.com`.  
- **Task:** List all CRDs in the cluster and save the list to a file named `/opt/crds.txt`. Then, use `kubectl explain` to find the documentation for the `spec.vault.address` field of the `VaultSecret` CRD and save this documentation to `/opt/crd_field.txt`.  
- **Validation:** Check the contents of the two files, `/opt/crds.txt` and `/opt/crd_field.txt`, to ensure they contain the correct information.  

---

## Question 14: Create a Specific RBAC Role

- **Scenario:** A new developer, `david`, needs read-only access to pods and services in the `dev` namespace.  
- **Initial State:** The `dev` namespace exists. A user `david` is present in the cluster's authentication system.  
- **Task:** Create a Role named `pod-service-reader` in the `dev` namespace that grants `get`, `list`, and `watch` permissions on pods and services. Then, create a RoleBinding named `david-reader-binding` to bind the `david` user to this new role.  
- **Validation:** Run `kubectl auth can-i get pods --as david -n dev`. The result should be `yes`. Run `kubectl auth can-i delete pods --as david -n dev`. The result should be `no`.  

---

## Question 15: Create a Cluster-Wide RBAC Role

- **Scenario:** A cluster-wide auditing tool needs permission to view all nodes and persistent volumes in the cluster.  
- **Initial State:** A `ServiceAccount` named `auditor` exists in the `kube-system` namespace.  
- **Task:** Create a `ClusterRole` named `node-pv-viewer` that grants `get` and `list` permissions on nodes and persistent volumes. Create a `ClusterRoleBinding` named `auditor-global-binding` to grant the `auditor` ServiceAccount this ClusterRole.  
- **Validation:** Run `kubectl auth can-i list nodes --as=system:serviceaccount:kube-system:auditor`. The result should be `yes`.  

---

## Question 16: Upgrade a kubeadm Cluster

- **Scenario:** The cluster is running Kubernetes version `1.28.1` and needs to be upgraded to the latest patch release of `1.28`.  
- **Initial State:** A single-node kubeadm cluster is running version `1.28.1`.  
- **Task:** On the control plane node, update the package manager and install the target version of `kubeadm`. Run `kubeadm upgrade plan` to verify the upgrade path. Then, apply the upgrade using `kubeadm upgrade apply v1.28.x` (where `x` is the latest patch). After the control plane is upgraded, drain the node, upgrade `kubelet` and `kubectl`, and then uncordon the node.  
- **Validation:** Run `kubectl get nodes`. The version column should reflect the new Kubernetes version.  

---

## Question 17: Backup etcd

- **Scenario:** As part of a disaster recovery plan, you need to perform a manual backup of the etcd database.  
- **Initial State:** The cluster is running with an etcd instance managed by kubeadm as a static pod.  
- **Task:** Using the `etcdctl` binary, create a snapshot of the etcd database. You will need to provide the correct endpoint, CA certificate, client certificate, and key, which can be found by inspecting the etcd static pod manifest. Save the snapshot to `/opt/etcd-backup.db`.  
- **Validation:** Run `etcdctl snapshot status /opt/etcd-backup.db` to verify the integrity of the backup file.  

---

## Question 18: Add a New Worker Node

- **Scenario:** The cluster needs more capacity, and a new machine is ready to be joined as a worker node.  
- **Initial State:** A one-control-plane, one-worker cluster exists. A new machine `new-worker` is provisioned with a container runtime.  
- **Task:** On the control plane node, generate a new `kubeadm join` token. SSH to the `new-worker` machine and use the generated command (`kubeadm join ...`) to join the node to the cluster.  
- **Validation:** From the control plane, run `kubectl get nodes`. The `new-worker` node should appear in the list with a `Ready` status after a few moments.  

---

## Question 19: Use Kustomize to Apply a Variant

- **Scenario:** An application has base configurations, but you need to deploy a staging variant with increased replica counts.  
- **Initial State:** A directory `/opt/app` contains a `kustomization.yaml` and a `deployment.yaml` (with 1 replica). A subdirectory `/opt/app/overlays/staging` contains another `kustomization.yaml`.  
- **Task:** Edit the Kustomization file in `/opt/app/overlays/staging` to use the base configuration but patch the Deployment to have 3 replicas. Then, apply the staging configuration to the cluster using `kubectl apply -k /opt/app/overlays/staging`.  
- **Validation:** Run `kubectl get deployment` and verify that the application's deployment has 3 replicas running.  

---

## Question 20: Configure an External CRI

- **Scenario:** A node is configured to use dockerd, but policy requires it to use containerd.  
- **Initial State:** A worker node `worker-1` has both dockerd and containerd installed. The kubelet is configured to use the docker runtime socket.  
- **Task:** SSH to `worker-1`. Drain the node. Stop the kubelet. Edit the kubelet configuration (`/var/lib/kubelet/kubeadm-flags.env` or similar) to point to the containerd socket (`--container-runtime-endpoint=unix:///run/containerd/containerd.sock`). Restart the kubelet. Uncordon the node.  
- **Validation:** Run `kubectl describe node worker-1`. The Container Runtime Version should show `containerd://...`.  

---


## Domain: Services & Networking (10 Questions)

## Question 21: Expose a Deployment with a NodePort Service

- **Scenario:** A deployment named `webapp` is running in the `app-space` namespace, and it needs to be accessible from outside the cluster for testing purposes.  
- **Initial State:** A Deployment `webapp` with 2 replicas is running in the `app-space` namespace. The pods expose port `8080`.  
- **Task:** Create a Service named `webapp-svc` of type `NodePort` in the `app-space` namespace. The service should expose port `80` on the service itself, target port `8080` on the pods, and expose node port `30080` on the cluster nodes.  
- **Validation:** Run `curl <node-ip>:30080` from the base node. It should return a response from the `webapp`.  

---

## Question 22: Create an Ingress Resource

- **Scenario:** An application, served by `app-svc`, needs to be exposed externally via HTTP routing at the path `/app`.  
- **Initial State:** An Ingress controller is running. A service `app-svc` exists in the `default` namespace and exposes port `80`.  
- **Task:** Create an Ingress resource named `app-ingress`. It should route traffic for the path `/app` to the `app-svc` service on port `80`.  
- **Validation:** Find the external IP of the Ingress controller and run `curl http://<ingress-ip>/app`. It should connect to the `app-svc`.  

---

## Question 23: Ingress to Gateway API Migration

- **Scenario:** The organization is standardizing on the Gateway API. An existing application exposed via Ingress must be migrated.  
- **Initial State:** An Ingress resource `legacy-ingress` routes traffic for `app.example.com` to `app-svc`. A `GatewayClass` named `gw-class` exists. A TLS secret `app-tls` exists.  
- **Task:** Create a `Gateway` resource named `main-gateway` that uses the `gw-class` and listens on port `443` for HTTPS traffic from `app.example.com`, using the `app-tls` secret. Create an `HTTPRoute` named `app-route` that attaches to this gateway and routes requests for `app.example.com` to the `app-svc` service. After verifying the route works, delete the `legacy-ingress`.  
- **Validation:** Test connectivity to `https://app.example.com` (using `curl --resolve`). After confirming it works, verify that `kubectl get ingress legacy-ingress` returns “not found.”  

---

## Question 24: Restrict Ingress Traffic with a Network Policy

- **Scenario:** A database in the `db` namespace should only accept connections from the application frontend in the `frontend` namespace.  
- **Initial State:** Pods in the `frontend` namespace (with label `app=frontend`) need to connect to pods in the `db` namespace (with label `app=db`) on port `5432`.  
- **Task:** Create a Network Policy named `db-allow-frontend` in the `db` namespace. This policy should apply to pods with the label `app=db`. It should define an ingress rule that allows traffic on TCP port `5432` only from pods in a namespace that has the label `name=frontend`.  
- **Validation:** Exec into a pod in the `frontend` namespace and confirm it can connect to the DB service. Exec into a pod in another namespace (e.g., `default`) and confirm the connection is blocked.  

---

## Question 25: Allow Egress Traffic with a Network Policy

- **Scenario:** An application pod needs to make API calls to an external service at `192.0.2.10/32`, but all other outbound traffic should be blocked.  
- **Initial State:** A pod with label `app=api-client` in the `default` namespace. A default-deny egress policy is in effect for the namespace.  
- **Task:** Create a Network Policy named `allow-external-api` that applies to pods with `app=api-client`. The policy should define an egress rule that allows traffic to the IP block `192.0.2.10/32` on TCP port `443`.  
- **Validation:** Exec into the `api-client` pod. Confirm that `curl https://192.0.2.10` works, but `curl https://google.com` times out.  

---

## Question 26: Create a Headless Service

- **Scenario:** A StatefulSet of database replicas requires a headless service for direct pod discovery.  
- **Initial State:** A StatefulSet named `db-statefulset` with 3 replicas exists. The pods have the label `app=db`.  
- **Task:** Create a headless Service named `db-svc-headless`. It should target pods with the label `app=db`. To make it headless, set the `clusterIP` field to `None`.  
- **Validation:** Run `nslookup db-svc-headless`. It should return the individual IP addresses of the three database pods.  

---

## Question 27: Select the Correct Network Policy Manifest

- **Scenario:** You are given three manifest files: `/opt/np-1.yaml`, `/opt/np-2.yaml`, and `/opt/np-3.yaml`. You must apply the one that implements a specific security rule.  
- **Initial State:** Three YAML files containing Network Policy definitions.  
- **Task:** Analyze the files to determine which one correctly implements the following rule: “In the backend namespace, allow ingress traffic on port 8000 to pods with label `role=api` only from pods that have the label `role=frontend`.” Apply the correct manifest file.  
- **Validation:** Test connectivity from a `frontend` pod to an `api` pod (should succeed) and from another pod (should fail).  

---

## Question 28: Configure Pod DNS Policy

- **Scenario:** A legacy application pod needs to use a specific external DNS server instead of the cluster’s CoreDNS.  
- **Initial State:** A pod manifest `/opt/legacy-pod.yaml` exists.  
- **Task:** Edit the pod manifest `/opt/legacy-pod.yaml`. Set the `dnsPolicy` to `None`. Add a `dnsConfig` section that specifies `8.8.4.4` in the `nameservers` list. Create the pod.  
- **Validation:** Exec into the created pod and inspect the contents of `/etc/resolv.conf`. It should show `nameserver 8.8.4.4`.  

---

## Question 29: Use a LoadBalancer Service

- **Scenario:** An application needs to be exposed to the internet using a cloud provider’s load balancer.  
- **Initial State:** A Deployment `public-api` is running. The environment is a simulated cloud environment.  
- **Task:** Create a Service named `api-lb` of type `LoadBalancer`. It should target the `public-api` pods on port `8080`.  
- **Validation:** Run `kubectl get service api-lb`. After a moment, an `EXTERNAL-IP` should be assigned by the simulated cloud provider.  

---

## Question 30: Modify CoreDNS for Custom Domains

- **Scenario:** You need CoreDNS to resolve a custom domain `internal.corp` to a specific IP address.  
- **Initial State:** CoreDNS is running.  
- **Task:** Edit the `coredns` ConfigMap in the `kube-system` namespace. Add a `hosts` block to the Corefile configuration that maps `service.internal.corp` to the IP `10.0.5.20`. Restart the CoreDNS pods.  
- **Validation:** Exec into a test pod and run `nslookup service.internal.corp`. It should resolve to `10.0.5.20`.  

---


## Domain: Workloads & Scheduling (10 Questions)

## Question 31: Configure a Horizontal Pod Autoscaler

- **Scenario:** A CPU-intensive workload needs to scale automatically based on load.  
- **Initial State:** A Deployment named `processor` is running. The pods in the deployment have CPU resource requests set.  
- **Task:** Create a HorizontalPodAutoscaler named `processor-hpa`. It should target the `processor` Deployment, maintain a minimum of 2 and a maximum of 6 replicas, and scale up when the average CPU utilization across pods exceeds 60%.  
- **Validation:** Run `kubectl describe hpa processor-hpa` to verify its configuration.  

---

## Question 32: Calculate and Set Resource Limits

- **Scenario:** A Deployment is causing instability by consuming too many resources on a node. You need to constrain it based on available node capacity.  
- **Initial State:** A node `worker-1` has 2000m of allocatable CPU and 4Gi of allocatable memory. A Deployment `resource-hog` with 2 replicas is running on it.  
- **Task:** Calculate resource limits for the `resource-hog` pods. Each pod should be limited to `400m` CPU and `512Mi` of memory. Edit the `resource-hog` Deployment and set these values in the `resources.limits` section of the container spec.  
- **Validation:** Describe one of the `resource-hog` pods and verify that the CPU and memory limits are correctly set.  

---

## Question 33: Use a PriorityClass for a Critical Pod

- **Scenario:** A critical monitoring agent must be scheduled even if the cluster is under high load.  
- **Initial State:** A pod manifest `/opt/agent.yaml` exists.  
- **Task:** Create a `PriorityClass` named `high-priority` with a value of `1000000`. Edit the pod manifest `/opt/agent.yaml` to use this priority class by setting the `priorityClassName` field to `high-priority`. Create the pod.  
- **Validation:** Describe the created pod and verify that the **Priority Class** field is set to `high-priority`.  

---

## Question 34: Add a Sidecar Container

- **Scenario:** An existing application pod needs a sidecar container to stream its logs to a central service.  
- **Initial State:** A Deployment `main-app` is running. The application writes logs to `/var/log/app.log` inside a volume.  
- **Task:** Edit the `main-app` Deployment. Add a new container to the pod spec named `log-streamer` using the `busybox` image. The new container should run the command `tail -f /var/log/app.log`. Mount the same log volume that the main application uses into this new sidecar container.  
- **Validation:** Describe one of the pods from the `main-app` Deployment. It should show two containers: the main app container and the `log-streamer`.  

---

## Question 35: Perform a Rolling Update and Rollback

- **Scenario:** You need to update an application to a new version and then roll it back due to a reported bug.  
- **Initial State:** A Deployment `frontend` is running version `1.0` of an application image.  
- **Task:** Update the `frontend` Deployment to use image version `1.1`. After the update completes, perform a rollback to the previous version.  
- **Validation:** Run `kubectl rollout history deployment frontend` to see the revision history. After the rollback, describe the deployment and verify that it is using image version `1.0` again.  

---

## Question 36: Use a ConfigMap to Configure an Application

- **Scenario:** An NGINX pod needs to be configured with a custom `nginx.conf` file.  
- **Initial State:** A file `/opt/nginx.conf` exists with custom settings.  
- **Task:** Create a ConfigMap named `nginx-config` from the file `/opt/nginx.conf`. Then, create a pod that runs the `nginx` image. Mount the `nginx-config` ConfigMap as a volume into the pod at the path `/etc/nginx/nginx.conf`, overwriting the default configuration file.  
- **Validation:** Exec into the pod and run `cat /etc/nginx/nginx.conf`. The content should match the custom file from `/opt/nginx.conf`.  

---

## Question 37: Use a Secret for Environment Variables

- **Scenario:** An application requires a database password, which must be supplied securely as an environment variable.  
- **Initial State:** A pod manifest `/opt/app-pod.yaml` exists.  
- **Task:** Create a generic Secret named `db-secret` with a key `DB_PASSWORD` and a value of `s3cr3tP@ssw0rd`. Edit the pod manifest `/opt/app-pod.yaml` to expose the `DB_PASSWORD` key from the `db-secret` as an environment variable named `DATABASE_PASSWORD` in the container. Create the pod.  
- **Validation:** Exec into the pod and run `env | grep DATABASE_PASSWORD`. It should show `DATABASE_PASSWORD=s3cr3tP@ssw0rd`.  

---

## Question 38: Configure Node Affinity

- **Scenario:** A specific workload must only run on nodes that have high-performance SSD storage.  
- **Initial State:** Some worker nodes have the label `disktype=ssd`. A Deployment manifest `/opt/workload.yaml` exists.  
- **Task:** Edit the Deployment manifest `/opt/workload.yaml`. Add a `nodeAffinity` rule under `spec.template.spec.affinity`. The rule should be a `requiredDuringSchedulingIgnoredDuringExecution` type that requires nodes to have the label `disktype` with the value `ssd`. Apply the manifest.  
- **Validation:** Check which nodes the deployment’s pods are running on using `kubectl get pods -o wide`. All pods should be on nodes with the `disktype=ssd` label.  

---

## Question 39: Configure Taints and Tolerations

- **Scenario:** A specific node is reserved for GPU workloads and should not accept normal pods.  
- **Initial State:** A node `gpu-node-1` exists. A pod manifest `/opt/gpu-pod.yaml` exists.  
- **Task:** Add a taint to the `gpu-node-1` node with the key `gpu`, value `true`, and effect `NoSchedule`. Then, edit the pod manifest `/opt/gpu-pod.yaml` to add a toleration for this taint (`key: "gpu"`, `operator: "Exists"`, `effect: "NoSchedule"`). Create the pod.  
- **Validation:** The `gpu-pod` should be successfully scheduled on `gpu-node-1`. A normal pod without the toleration should not be scheduled on that node.  

---

## Question 40: Create a StatefulSet

- **Scenario:** Deploy a stateful application that requires stable network identifiers and persistent storage.  
- **Initial State:** A headless service `app-headless` and a StorageClass `fast-storage` exist.  
- **Task:** Create a StatefulSet named `data-app` with 2 replicas. It should use the `app-headless` service for its `serviceName`. The pod template should use the `nginx` image. Define a `volumeClaimTemplate` that creates a 1Gi PVC for each replica using the `fast-storage` StorageClass.  
- **Validation:** Verify that two pods, `data-app-0` and `data-app-1`, are created and running. Verify that two corresponding PVCs have also been created and bound.  

---

## Domain: Storage (10 Questions)

## Question 41: Create a PVC and Mount it in a Pod

- **Scenario:** An application needs a persistent volume to store its data.  
- **Initial State:** A default StorageClass is configured in the cluster.  
- **Task:** Create a PersistentVolumeClaim named `my-pvc` that requests `1Gi` of storage with the `ReadWriteOnce` access mode. Then, create a pod named `storage-pod` that mounts this PVC at the path `/data`.  
- **Validation:** Exec into the `storage-pod` and create a file in the `/data` directory. Delete the pod. Recreate the pod. Exec into the new pod and verify that the file still exists in `/data`.  

---

## Question 42: Patch a StorageClass to be the Default

- **Scenario:** The cluster has two StorageClasses, `slow` and `fast`, but neither is the default. You need to make `fast` the default for all new PVCs.  
- **Initial State:** Two StorageClasses, `slow` and `fast`, exist.  
- **Task:** Use the `kubectl patch` command to add the annotation `storageclass.kubernetes.io/is-default-class="true"` to the `fast` StorageClass. Ensure the `slow` StorageClass does not have this annotation.  
- **Validation:** Create a new PVC without specifying a `storageClassName`. Describe the PVC and verify that it was provisioned using the `fast` StorageClass.  

---

## Question 43: Create a PVC to Bind to a Specific PV

- **Scenario:** A PersistentVolume named `pv-data-001` was created manually, and you need to create a claim that specifically binds to it.  
- **Initial State:** A PV named `pv-data-001` exists with a capacity of `2Gi`, access mode `ReadWriteOnce`, and `storageClassName` of `manual`.  
- **Task:** Create a PersistentVolumeClaim named `claim-for-pv-data` that exactly matches the specifications of `pv-data-001` (requests 2Gi storage, ReadWriteOnce access mode, and `storageClassName: manual`) to ensure it binds to that specific PV.  
- **Validation:** Run `kubectl get pvc claim-for-pv-data`. Its status should be `Bound`, and describing it should show it is bound to the `pv-data-001` volume.  

---

## Question 44: Configure Volume Reclaim Policy

- **Scenario:** You are creating a PersistentVolume for temporary data and want the underlying storage to be deleted when the claim is released.  
- **Initial State:** A manifest for a PV is at `/opt/pv.yaml`.  
- **Task:** Edit the PV manifest at `/opt/pv.yaml`. Set the `persistentVolumeReclaimPolicy` field to `Delete`. Create the PV.  
- **Validation:** Create a PVC that binds to this PV. Then, delete the PVC. The PV's status should change to `Terminating` and it should eventually be deleted.  

---

## Question 45: Expand a Persistent Volume Claim

- **Scenario:** An application's database is running out of space, and the underlying storage volume needs to be expanded.  
- **Initial State:** A StorageClass `expandable-sc` with `allowVolumeExpansion: true` exists. A PVC `db-pvc` created with this class is currently `10Gi`.  
- **Task:** Edit the `db-pvc` PersistentVolumeClaim and change the `spec.resources.requests.storage` value from `10Gi` to `20Gi`.  
- **Validation:** Run `kubectl describe pvc db-pvc`. Check the events to see a successful resize operation. The capacity of the PVC should now show `20Gi`.  

---

## Question 46: Use a HostPath Volume

- **Scenario:** A pod needs to access logs stored directly on the node's filesystem for debugging.  
- **Initial State:** A log file exists at `/var/log/node-app.log` on a worker node.  
- **Task:** Create a pod that uses a `hostPath` volume to mount the `/var/log` directory from the host node into the pod at the path `/node-logs`. The pod should be scheduled to the specific worker node where the log file exists.  
- **Validation:** Exec into the pod and run `cat /node-logs/node-app.log`. It should display the contents of the log file from the host node.  

---

## Question 47: Use an emptyDir Volume for Temporary Data

- **Scenario:** Two containers in a pod need to share temporary files.  
- **Initial State:** A pod manifest `/opt/multi-container-pod.yaml` defines two containers.  
- **Task:** Edit the pod manifest. Define an `emptyDir` volume named `shared-data`. Mount this volume into both containers at the path `/shared`. Create the pod.  
- **Validation:** Exec into the first container and create a file in `/shared`. Then, exec into the second container and verify that the file is visible and accessible at `/shared`.  

---

## Question 48: Create a Read-Only Volume Mount

- **Scenario:** A pod needs to read configuration data from a ConfigMap, but it must be prevented from modifying the data.  
- **Initial State:** A ConfigMap `app-config` exists.  
- **Task:** Create a pod. Mount the `app-config` ConfigMap as a volume. In the `volumeMounts` section for the container, set the `readOnly` field to `true`.  
- **Validation:** Exec into the pod and attempt to write a file to the mounted config directory (e.g., `touch /path/to/config/new-file`). The command should fail with a "Read-only file system" error.  

---

## Question 49: Manually Create a PersistentVolume

- **Scenario:** You have an existing NFS share and need to make it available as a volume in the cluster.  
- **Initial State:** An NFS server is running at `192.168.1.100` with an exported path `/data/shared`.  
- **Task:** Create a PersistentVolume manifest. The PV should have a capacity of `5Gi`, access mode `ReadWriteMany`, and a `reclaimPolicy` of `Retain`. The volume source should be `nfs`, with the server set to `192.168.1.100` and the path to `/data/shared`. Apply the manifest.  
- **Validation:** Run `kubectl get pv`. The new PV should be listed with the status `Available`.  

---

## Question 50: Clone a Persistent Volume Claim

- **Scenario:** You need to create a pre-populated volume for a new testing environment by cloning an existing PVC.  
- **Initial State:** A PVC `source-pvc` exists and is bound. The underlying CSI driver supports volume cloning.  
- **Task:** Create a new PVC manifest for a PVC named `cloned-pvc`. In the `spec`, add a `dataSource` block that specifies `name: source-pvc` and `kind: PersistentVolumeClaim`. Apply the manifest.  
- **Validation:** Run `kubectl get pvc cloned-pvc`. It should become `Bound`. Create a pod that mounts `cloned-pvc`, and verify that it contains the same data as the `source-pvc`.  

