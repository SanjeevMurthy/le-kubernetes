## Section 1: The questions I Got I got 16 questions, and all of these are based on some scenario which was already built in each question’s cluster.

Select one out of the three NetworkPolicy manifests which matches the scenario described in the question (e.g., backend pods should only have ingress traffic from the frontend namespace).
Install the cridocker .deb package using the dpkg -i command and perform some follow-up tasks.
List all CRDs matching a keyword (cert-manager) and write them into a file. Then, document a field from the spec of the CRD using the kubectl explain command.
Expose a deployment using a NodePort service.
Create an HPA (Horizontal Pod Autoscaler) for an existing deployment.
Create an Ingress resource matching the scenario described in the question.
Create a Gateway with TLS and an HTTPRoute, matching the existing Ingress resource in the environment. Delete the Ingress after creating the Gateway.
Generate a Helm template and save it to a file using the helm template command. Then install the Helm chart with some changes to the Helm values. Both tasks were in a specific namespace, and a specific chart version was mentioned.
Create a PriorityClass with a modification compared to an existing user-defined PriorityClass.
Create a StorageClass.
Create a PVC and attach it to a Pod. There was an existing PV in the environment, and we had to choose PVC properties to match the PV.
Add a sidecar log container to an existing deployment by mounting a shared volume.
Change the ConfigMap properties of an existing NGINX ConfigMap to enable both TLSv1.2 and TLSv1.3. Only TLSv1.3 was enabled initially.
A deployment with three replicas had some pods in a pending state because the resource requests of containers exceeded the resources available on the node. Check the node’s CPU and memory, then divide them equally among the containers — keeping some overhead for system components and buffer — so that the deployment schedules all three replicas without any being pending.
kube-apiserver and kube-scheduler in a cluster were not working, but etcd, kube-controller-manager, and kubelet were. Troubleshoot and fix the issue.
Choose a CNI between Flannel and Calico that has built-in support for Network Policies (Calico supports them). Install the CNI and configure it to work with the current node’s PodCIDR.

## Section 2.1 Questions i had issues with:

(No 14 of above) — The deployment manifest was too bulky because it had unnecessary length due to extra new lines. It also included Init Containers. I tried to divide the resources properly, but something went wrong every time, so the pods didn’t become ready. Probably my mistake, but I’m sharing it anyway.
(No 15 of above) — In the kube-apiserver.yaml, the etcd-server URL was wrong—I corrected it. That was the only issue I found. All certificate paths were correct. But still, the kube-apiserver did not start, and I couldn't find the root cause of the kube-scheduler failure either.
(No 16 of above) — The Calico tigera-operator.yaml URL was provided. The custom-resources.yaml URL was not, but we needed it to configure the PodCIDR in the Installation CRD. Anyway, I remembered the path for custom-resources.yaml as it was in the same directory. But even then, errors were thrown when I did kubectl apply with the tigera-operator.yaml. The following error came:

## Section 2.2 Questions i think i went wrong are:

Install containerd from dpkg package — install from .deb packages, make necessary config changes (SystemdCgroup), and start the containerd service
Troubleshoot a failed cluster — kubelet not working, couldn't get kube-apiserver logs, failed to use crictl commands to troubleshoot the cluster
Install CNI plugin (Calico or Flannel) — make necessary config changes and verify pod IPs are getting assigned
Helm install ArgoCD — use Helm to install ArgoCD and verify the installation
Replace Ingress with Gateway API + TLS — replace an existing Ingress resource (with TLS using a secret) with a Gateway and HTTPRoute
cert-manager CRD exploration — list all cert-manager CRDs, find the spec.subject field from the Certificates CRD using kubectl explain, and write the content to a file
RBAC for custom resources — CRDs already installed for custom objects like students and classes, create Role/RoleBinding that grants permission to create/manage these custom objects
Questions 1, 3, 6, and 7 fall under Cluster Architecture, Installation & Configuration (25%). Question 2 falls under Troubleshooting (30%). Question 4 under Workloads & Scheduling (15%). Question 5 under Services & Networking (20%). All three of these domains were flagged as your lowest scoring in the exam results email.

## Section 3: Below are some of the Questions with solutions:

SIMULATION

You must connect to the correct host.

Failure to do so may result in a zero score.

[candidate@base] $ ssh Cka000055

Task

Verify the cert-manager application which has been deployed to your cluster .

Using kubectl, create a list of all cert-manager Custom Resource Definitions (CRDs ) and save it

to ~/resources.yaml .

You must use kubectl 's default output format.

Do not set an output format.

Failure to do so will result in a reduced score.

Using kubectl, extract the documentation for the subject specification field of the Certificate Custom Resource and save it to ~/subject.yaml.

Explanation:
Task Summary

You need to:

SSH into the correct node: cka000055

Use kubectl to list all cert-manager CRDs, and save that list to ~/resources.yaml

Do not use any output format flags like -o yaml

Extract the documentation for the spec.subject field of the Certificate custom resource and save it to ~/subject.yaml

Step-by-Step Instructions

Step 1: SSH into the node

ssh cka000055

Step 2: List cert-manager CRDs and save to a file

First, identify all cert-manager CRDs:

kubectl get crds | grep cert-manager

Then extract them without specifying an output format:

kubectl get crds | grep cert-manager | awk '{print $1}' | xargs kubectl get crd > ~/resources.yaml

This saves the default kubectl get output to the required file without formatting flags.

Step 3: Get documentation for spec.subject in the Certificate CRD

Run the following command:

kubectl explain certificate.spec.subject > ~/subject.yaml

This extracts the field documentation and saves it to the specified file.

If you're not sure of the resource, verify it exists:

kubectl get crd [certificates.cert-manager.io](http://certificates.cert-manager.io/)

Final Command Summary

ssh cka000055

kubectl get crds | grep cert-manager | awk '{print $1}' | xargs kubectl get crd > ~/resources.yaml

kubectl explain certificate.spec.subject > ~/subject.yaml

---

SIMULATION

Quick Reference

ConfigMaps,

Documentation Deployments,

Namespace

You must connect to the correct host . Failure to do so may result in a zero score.

[candidate@base] $ ssh cka000048b

Task

An NGINX Deployment named nginx-static is running in the nginx-static namespace. It is configured using a ConfigMap named nginx-config .

First, update the nginx-config ConfigMap to also allow TLSv1.2. connections.

You may re-create, restart, or scale resources as necessary.

You can use the following command to test the changes:

[candidate@cka000048b] $ curl -- tls-max

1.2 [https://web.k8s.local](https://web.k8s.local/)

Answer:

Explanation:
Task Summary

SSH into cka000048b

Update the nginx-config ConfigMap in the nginx-static namespace to allow TLSv1.2

Ensure the nginx-static Deployment picks up the new config

Verify the change using the provided curl command

Step-by-Step Instructions

Step 1: SSH into the correct host

ssh cka000048b

Step 2: Get the ConfigMap

kubectl get configmap nginx-config -n nginx-static -o yaml > nginx-config.yaml

Open the file for editing:

nano nginx-config.yaml

Look for the TLS configuration in the data field. You are likely to find something like:

ssl_protocols TLSv1.3;

Modify it to include TLSv1.2 as well:

ssl_protocols TLSv1.2 TLSv1.3;

Save and exit the file.

Now update the ConfigMap:

kubectl apply -f nginx-config.yaml

Step 3: Restart the NGINX pods to pick up the new ConfigMap

Pods will not reload a ConfigMap automatically unless it's mounted in a way that supports dynamic reload and the app is watching for it (NGINX typically doesn't by default).

The safest way is to restart the pods:

Option 1: Roll the deployment

kubectl rollout restart deployment nginx-static -n nginx-static

Option 2: Delete pods to force recreation

kubectl delete pod -n nginx-static -l app=nginx-static

Step 4: Verify using curl

Use the provided curl command to confirm that TLS 1.2 is accepted:

curl --tls-max 1.2 [https://web.k8s.local](https://web.k8s.local/)

A successful response means the TLS configuration is correct.

Final Command Summary

ssh cka000048b

kubectl get configmap nginx-config -n nginx-static -o yaml > nginx-config.yaml

nano nginx-config.yaml # Modify to include 'ssl_protocols TLSv1.2 TLSv1.3;'

kubectl apply -f nginx-config.yaml

kubectl rollout restart deployment nginx-static -n nginx-static

# or

kubectl delete pod -n nginx-static -l app=nginx-static

curl --tls-max 1.2 [https://web.k8s.local](https://web.k8s.local/)

---

SIMULATION

You must connect to the correct host.

Failure to do so may result in a zero score.

[candidate@base] $ ssh Cka000059

Context

A kubeadm provisioned cluster was migrated to a new machine. It needs configuration changes to

run successfully.

Task

Fix a single-node cluster that got broken during machine migration.

First, identify the broken cluster components and investigate what breaks them.

The decommissioned cluster used an external etcd server.

Next, fix the configuration of all broken cluster

Explanation:
Task Summary

SSH into node: cka000059

Cluster was migrated to a new machine

It uses an external etcd server

Identify and fix misconfigured components

Bring the cluster back to a healthy state

Step-by-Step Solution

Step 1: SSH into the correct host

ssh cka000059

Step 2: Check the cluster status

Run:

kubectl get nodes

If it fails, the kubelet or kube-apiserver is likely broken.

Check kubelet status:

sudo systemctl status kubelet

Also, check pod statuses in the control plane:

sudo crictl ps -a | grep kube

or:

docker ps -a | grep kube

Look especially for failures in kube-apiserver or kube-controller-manager.

Step 3: Inspect the kube-apiserver manifest

Since this is a kubeadm-based cluster, manifests are in:

ls /etc/kubernetes/manifests

Open kube-apiserver.yaml:

bash

CopyEdit

sudo nano /etc/kubernetes/manifests/kube-apiserver.yaml

Look for the --etcd-servers= flag. If the external etcd endpoint has changed (likely, due to migration), this needs to be fixed.

Example of incorrect configuration:

- -etcd-servers=https://192.168.1.100:2379

If the IP has changed, update it to the correct IP or hostname of the external etcd server.

Also ensure the correct client certificate and key paths are still valid:

- -etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
- -etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt
- -etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key

If the files are missing or the path is wrong due to migration, correct those as well.

Step 4: Save and exit, and let static pod restart

Static pod changes will be picked up automatically by the kubelet (watch for /etc/kubernetes/manifests changes).

Check again:

docker ps | grep kube-apiserver

# or

crictl ps | grep kube-apiserver

Step 5: Confirm API is healthy

Once kube-apiserver is up, try:

kubectl get componentstatuses

kubectl get nodes

If these commands work and return valid statuses, the control plane is functional again.

Step 6: Check controller-manager and scheduler (optional)

If still broken, check the other static pods in /etc/kubernetes/manifests/ and correct paths if necessary.

Also verify that /etc/kubernetes/kubelet.conf and /etc/kubernetes/admin.conf are present and valid.

Command Summary

ssh cka000059

# Check system and kubelet

sudo systemctl status kubelet

docker ps -a | grep kube # or crictl ps -a | grep kube

# Check manifests

ls /etc/kubernetes/manifests

sudo nano /etc/kubernetes/manifests/kube-apiserver.yaml

# Fix --etcd-servers and certificate paths if needed

# Watch pods restart and confirm:

kubectl get nodes

kubectl get componentstatuses

---

SIMULATION

You must connect to the correct host.

Failure to do so may result in a zero score.

[candidate@base] $ ssh Cka000056

Task

Review and apply the appropriate NetworkPolicy from the provided YAML samples.

Ensure that the chosen NetworkPolicy is not overly permissive, but allows communication between the frontend and backend Deployments, which run in the frontend and backend namespaces respectively.

First, analyze the frontend and backend Deployments to determine the specific requirements for the NetworkPolicy that needs to be applied.

Next, examine the NetworkPolicy YAML samples located in the ~/netpol folder.

Failure to comply may result in a reduced score.

Do not delete or modify the provided samples. Only apply one of them.

Finally, apply the NetworkPolicy that enables communication between the frontend and backend Deployments, without being overly permissive.

Task Summary

Connect to host cka000056

Review existing frontend and backend Deployments

Choose one correct NetworkPolicy from the ~/netpol directory

The policy must:

Allow traffic only from the frontend Deployment to the backend Deployment

Avoid being overly permissive

Apply the correct NetworkPolicy without modifying any sample files

Step-by-Step Instructions

Step 1: SSH into the correct node

ssh cka000056

Step 2: Inspect the frontend Deployment

Check the labels used in the frontend Deployment:

kubectl get deployment -n frontend -o yaml

Look under metadata.labels or spec.template.metadata.labels. Note the app or similar label (e.g., app: frontend).

Step 3: Inspect the backend Deployment

kubectl get deployment -n backend -o yaml

Again, find the labels assigned to the pods (e.g., app: backend).

Step 4: List and review the provided NetworkPolicies

List the available files:

ls ~/netpol

Check the contents of each policy file:

cat ~/netpol/<file-name>.yaml

Look for a policy that:

Has kind: NetworkPolicy

Applies to the backend namespace

Uses a podSelector that matches the backend pods

Includes an ingress.from rule that references the frontend namespace using a namespaceSelector (and optionally a podSelector)

Does not allow traffic from all namespaces or all pods

Here's what to look for in a good match:

apiVersion: [networking.k8s.io/v1](http://networking.k8s.io/v1)

kind: NetworkPolicy

metadata:

name: allow-frontend-to-backend

namespace: backend

spec:

podSelector:

matchLabels:

app: backend

ingress:

- from:
- namespaceSelector:

matchLabels:

name: frontend

Even better if the policy includes:

- namespaceSelector:

matchLabels:

name: frontend

podSelector:

matchLabels:

app: frontend

This limits access to pods in the frontend namespace with a specific label.

Step 5: Apply the correct NetworkPolicy

Once you've identified the best match, apply it:

kubectl apply -f ~/netpol/<chosen-file>.yaml

Apply only one file. Do not alter or delete any existing sample.

ssh cka000056

kubectl get deployment -n frontend -o yaml

kubectl get deployment -n backend -o yaml

ls ~/netpol

cat ~/netpol/\*.yaml # Review carefully

kubectl apply -f ~/netpol/<chosen-file>.yaml

Command Summary

ssh cka000056

kubectl get deployment -n frontend -o yaml

kubectl get deployment -n backend -o yaml

ls ~/netpol

cat ~/netpol/\*.yaml # Review carefully

kubectl apply -f ~/netpol/<chosen-file>.yaml

---

SIMULATION

You must connect to the correct host.

Failure to do so may result in a zero score.

[candidate@base] $ ssh Cka000047

Task

A MariaDB Deployment in the mariadb namespace has been deleted by mistake. Your task is to restore the Deployment ensuring data persistence. Follow these steps:

Create a PersistentVolumeClaim (PVC ) named mariadb in the mariadb namespace with the

following specifications:

Access mode ReadWriteOnce

Storage 250Mi

You must use the existing retained PersistentVolume (PV ).

Failure to do so will result in a reduced score.

There is only one existing PersistentVolume .

Edit the MariaDB Deployment file located at ~/mariadb-deployment.yaml to use PVC you

created in the previous step.

Apply the updated Deployment file to the cluster.

Ensure the MariaDB Deployment is running and stable.

Explanation:
Task Overview

You're restoring a MariaDB deployment in the mariadb namespace with persistent data.

Tasks:

SSH into cka000047

Create a PVC named mariadb:

Namespace: mariadb

Access mode: ReadWriteOnce

Storage: 250Mi

Use the existing retained PV (there's only one)

Edit ~/mariadb-deployment.yaml to use the PVC

Apply the deployment

Verify MariaDB is running and stable

Step-by-Step Solution

1 SSH into the correct host

ssh cka000047

Required --- skipping = zero score

2 Inspect the existing PersistentVolume

kubectl get pv

Identify the only existing PV, e.g.:

NAME CAPACITY ACCESS MODES RECLAIM POLICY STATUS CLAIM STORAGECLASS

mariadb-pv 250Mi RWO Retain Available <none> manual

Ensure the status is Available, and it is not already bound to a claim.

3 Create the PVC to bind the retained PV

Create a file mariadb-pvc.yaml:

cat <<EOF > mariadb-pvc.yaml

apiVersion: v1

kind: PersistentVolumeClaim

metadata:

name: mariadb

namespace: mariadb

spec:

accessModes:

- ReadWriteOnce

resources:

requests:

storage: 250Mi

volumeName: mariadb-pv # Match the PV name exactly

EOF

Apply the PVC:

kubectl apply -f mariadb-pvc.yaml

This binds the PVC to the retained PV.

4 Edit the MariaDB Deployment YAML

Open the file:

nano ~/mariadb-deployment.yaml

Look under the spec.template.spec.containers.volumeMounts and spec.template.spec.volumes sections and update them like so:

Add this under the container:

yaml

CopyEdit

volumeMounts:

- name: mariadb-storage

mountPath: /var/lib/mysql

And under the pod spec:

volumes:

- name: mariadb-storage

persistentVolumeClaim:

claimName: mariadb

These lines mount the PVC at the MariaDB data directory.

5 Apply the updated Deployment

kubectl apply -f ~/mariadb-deployment.yaml

6 Verify the Deployment is running and stable

kubectl get pods -n mariadb

kubectl describe pod -n mariadb <mariadb-pod-name>

Ensure the pod is in Running state and volume is mounted.

Final Command Summary

ssh cka000047

kubectl get pv # Find the retained PV

# Create PVC

cat <<EOF > mariadb-pvc.yaml

apiVersion: v1

kind: PersistentVolumeClaim

metadata:

name: mariadb

namespace: mariadb

spec:

accessModes:

- ReadWriteOnce

resources:

requests:

storage: 250Mi

volumeName: mariadb-pv

EOF

kubectl apply -f mariadb-pvc.yaml

# Edit Deployment

nano ~/mariadb-deployment.yaml

# Add volumeMount and volume to use the PVC as described

kubectl apply -f ~/mariadb-deployment.yaml

kubectl get pods -n mariadb

---

SIMULATION

You must connect to the correct host.

Failure to do so may result in a zero score.

[candidate@base] $ ssh Cka000054

Context:

Your cluster 's CNI has failed a security audit. It has been removed. You must install a new CNI

that can enforce network policies.

Task

Install and set up a Container Network Interface (CNI ) that meets these requirements:

Pick and install one of these CNI options:

- Flannel version 0.26.1

Manifest:

https://github.com/flannel-io/flannel/releases/download/v0.26.1/kube-flannel.yml

- Calico version 3.28.2

Manifest:

https://raw.githubusercontent.com/project calico/calico/v3.28.2/manifests/tigera-operator.yaml

Task Summary

SSH into cka000054

Install a CNI plugin that supports NetworkPolicies

Two CNI options provided:

Flannel v0.26.1 ( does NOT support NetworkPolicies)

Calico v3.28.2 (does support NetworkPolicies)

Decision Point: Which CNI to choose?

Choose Calico, because only Calico supports enforcing NetworkPolicies natively. Flannel does not.

Step-by-Step Solution

1 SSH into the correct node

ssh cka000054

Required. Skipping this results in zero score.

2 Install Calico CNI (v3.28.2)

Use the official manifest provided:

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml

This installs the Calico Operator, which then deploys the full Calico CNI stack.

3 Wait for Calico components to come up

Check the pods in tigera-operator and calico-system namespaces:

kubectl get pods -n tigera-operator

kubectl get pods -n calico-system

You should see pods like:

calico-kube-controllers

calico-node

calico-typha

tigera-operator

Wait for all to be in Running state.

(Optional) 4 Confirm CNI is enforcing NetworkPolicies

You can check:

kubectl get crds | grep networkpolicy

You should see:

[networkpolicies.crd.projectcalico.org](http://networkpolicies.crd.projectcalico.org/)

This confirms Calico's CRDs are installed for policy enforcement.

Final Command Summary

ssh cka000054

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml

kubectl get pods -n tigera-operator

kubectl get pods -n calico-system

kubectl get crds | grep networkpolicy

---
