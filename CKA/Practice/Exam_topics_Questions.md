# CKA Exam Practice Questions & Solutions

This document contains a detailed analysis and solution guide for CKA practice questions, grouped by the official CKA syllabus topics (2024/2025).

**Total Questions Processed:** 23 (including duplicates/variants)

---

## 1. Cluster Architecture, Installation & Configuration (25%)

### Question 1 & 21 (v1): RBAC Configuration

**Task:**
Create a new ClusterRole named `deployment-clusterrole`, which only allows to create the following resource types: Deployment, ReplicaSet, StatefulSet, DaemonSet.
Create a new ServiceAccount named `cicd-token` in the existing namespace `app-team1`.
Bind the new ClusterRole `deployment-clusterrole` to the new ServiceAccount `cicd-token`, limited to the namespace `app-team1`.

**Solution:**

1.  **Create the ClusterRole:**
    ```bash
    kubectl create clusterrole deployment-clusterrole \
      --verb=create \
      --resource=deployments,replicasets,statefulsets,daemonsets
    ```
2.  **Create the ServiceAccount:**
    ```bash
    kubectl create serviceaccount cicd-token -n app-team1
    ```
3.  **Create the RoleBinding:**
    _Note: Since the access must be "limited to the namespace", we use a `RoleBinding` to bind the `ClusterRole` locally, rather than a `ClusterRoleBinding`._
    ```bash
    kubectl create rolebinding deployment-binding \
      --clusterrole=deployment-clusterrole \
      --serviceaccount=app-team1:cicd-token \
      --namespace=app-team1
    ```

---

### Question 3: Cluster Upgrade

**Task:**
Upgrade the master node only to version 1.22.2. Drain the node before upgrading and uncordon after. Upgrade kubelet and kubectl as well.

**Solution:**

1.  **Drain the node:**
    ```bash
    kubectl drain master --ignore-daemonsets
    ```
2.  **Upgrade kubeadm:**
    ```bash
    apt-get update && apt-get install -y kubeadm=1.22.2-00
    ```
3.  **Plan and Apply Upgrade:**
    ```bash
    kubeadm upgrade plan
    kubeadm upgrade apply v1.22.2
    ```
4.  **Upgrade kubelet and kubectl:**
    ```bash
    apt-get install -y kubelet=1.22.2-00 kubectl=1.22.2-00
    systemctl daemon-reload
    systemctl restart kubelet
    ```
5.  **Uncordon the node:**
    ```bash
    kubectl uncordon master
    ```

---

### Question 4: Etcd Snapshot & Restore

**Task:**
Create a snapshot of etcd at `https://127.0.0.1:2379` using provided certs. Then restore a previous snapshot from `/var/lib/backup/etcd-snapshot-previous.db`.

**Solution:**

1.  **Create Snapshot:**
    ```bash
    ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
      --cacert=/opt/KUB00601/ca.crt \
      --cert=/opt/KUB00601/etcd-client.crt \
      --key=/opt/KUB00601/etcd-client.key \
      snapshot save /var/lib/backup/etcd-snapshot.db
    ```
2.  **Restore Snapshot:**
    ```bash
    ETCDCTL_API=3 etcdctl snapshot restore /var/lib/backup/etcd-snapshot-previous.db \
      --data-dir=/var/lib/etcd-restored
    ```
3.  **Update Etcd Manifest (Required to apply restore):**
    - Edit `/etc/kubernetes/manifests/etcd.yaml`.
    - Update `hostPath` for `etcd-data` to point to `/var/lib/etcd-restored`.
    - Wait for etcd pod to restart.

---

## 2. Workloads & Scheduling (15%)

### Question 2: Node Maintenance

**Task:**
Set the node named `elk8s-node-0` as unavailable and reschedule all the pods running on it.

**Solution:**

```bash
kubectl drain elk8s-node-0 --ignore-daemonsets --force
```

_Note: `drain` automatically cordons the node (making it unavailable for new pods) and evicts existing pods, causing them to be rescheduled elsewhere._

---

### Question 7 & 22: Scaling Deployments

**Task:**
Scale the deployment `presentation` (or `guestbook`) to 3 (or 5) pods.

**Solution:**

```bash
kubectl scale deployment presentation --replicas=3
# OR
kubectl scale deployment guestbook --replicas=5
```

---

### Question 8 & 21 (v2): Node Selector

**Task:**
Schedule a pod named `nginx-kusc00401` with image `nginx` on a node with label `disk=ssd`.

**Solution:**

1.  **Generate YAML:**
    ```bash
    kubectl run nginx-kusc00401 --image=nginx --restart=Never --dry-run=client -o yaml > pod.yaml
    ```
2.  **Edit `pod.yaml` to add `nodeSelector`:**
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: nginx-kusc00401
    spec:
      nodeSelector:
        disk: ssd
      containers:
        - name: nginx
          image: nginx
    ```
3.  **Apply:**
    ```bash
    kubectl apply -f pod.yaml
    ```

---

### Question 10 & 20: Multi-Container Pods

**Task:**
Schedule a Pod named `kusc8` (or `basic1`) with 2 containers: `nginx` and `consul` (or `redis` and `consul`).

**Solution:**

1.  **Generate YAML:**
    ```bash
    kubectl run kusc8 --image=nginx --restart=Never --dry-run=client -o yaml > multi.yaml
    ```
2.  **Edit `multi.yaml`:**
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: kusc8
    spec:
      containers:
        - name: nginx
          image: nginx
        - name: consul
          image: consul
    ```
3.  **Apply:**
    ```bash
    kubectl apply -f multi.yaml
    ```

---

## 3. Services & Networking (20%)

### Question 5 & 19: Network Policies

**Task:**
Create a NetworkPolicy `allow-port-from-namespace` in namespace `fubar` (or `echo`). Allow pods in namespace `internal` to connect to port 9000 (or 9200). Deny all other access to that port.

**Solution:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-port-from-namespace
  namespace: fubar
spec:
  podSelector: {} # Applies to all pods in 'fubar'
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: internal # Assuming namespace 'internal' has label 'name=internal'
      ports:
        - protocol: TCP
          port: 9000
```

_Note: Verify the labels on the `internal` namespace using `kubectl get ns --show-labels` and adjust `matchLabels` accordingly._

---

### Question 6: Expose Deployment

**Task:**
Configure deployment `frontend` to expose port 80/tcp of container `nginx` as port name `http`. Create a service `frontend-svc` exposing this.

**Solution:**

1.  **Edit Deployment:**
    ```bash
    kubectl edit deployment frontend
    ```
    Add/Update ports in container spec:
    ```yaml
    ports:
      - containerPort: 80
        name: http
        protocol: TCP
    ```
2.  **Create Service:**
    ```bash
    kubectl expose deployment frontend --name=frontend-svc --port=80 --target-port=http --type=ClusterIP
    ```

---

### Question 17 & 18: Ingress

**Task:**
Create an nginx Ingress resource `hello-ing` in `ing-internal` exposing service `hello` on path `/hello` port 5678.

**Solution:**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-ing
  namespace: ing-internal
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - http:
        paths:
          - path: /hello
            pathType: Prefix
            backend:
              service:
                name: hello
                port:
                  number: 5678
```

_Apply using `kubectl apply -f ingress.yaml`._

---

## 4. Storage (10%)

### Question 11 & 23: Persistent Volume (hostPath)

**Task:**
Create a PV named `app-data`, capacity `2Gi`, access mode `ReadWriteOnce`, type `hostPath` at `/srv/app-data`.

**Solution:**

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: app-data
spec:
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /srv/app-data
```

---

### Question 16: PVC and Resizing

**Task:**
Create PVC `pvc-gv` (1Gi, csi-hostpath-sc, RWO). Create Pod `nginx-pv` mounting it at `/usr/share/nginx/html`. Then expand PVC to 7Gi.

**Solution:**

1.  **Create PVC:**
    ```yaml
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: pvc-gv
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
      storageClassName: csi-hostpath-sc
    ```
2.  **Create Pod:**
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: nginx-pv
    spec:
      containers:
        - name: nginx
          image: nginx
          volumeMounts:
            - mountPath: "/usr/share/nginx/html"
              name: my-vol
      volumes:
        - name: my-vol
          persistentVolumeClaim:
            claimName: pvc-gv
    ```
3.  **Expand PVC:**
    ```bash
    kubectl patch pvc pvc-gv -p '{"spec":{"resources":{"requests":{"storage":"7Gi"}}}}'
    ```
    _Note: The storage class must support resizing (`allowVolumeExpansion: true`)._

---

## 5. Troubleshooting (30%)

### Question 9: Node Status Count

**Task:**
Check how many nodes are ready (excluding NoSchedule tainted) and write count to `/opt/KUSC00402/kusc00402.txt`.

**Solution:**

```bash
kubectl get nodes --no-headers | grep -v NoSchedule | grep -w Ready | wc -l > /opt/KUSC00402/kusc00402.txt
```

_Verification:_ `cat /opt/KUSC00402/kusc00402.txt`

---

### Question 12: Log Monitoring

**Task:**
Monitor logs of pod `piot-env`. Filter for `error file-not-found`. Write to `/opt/KU1T00131/flog`.

**Solution:**

```bash
kubectl logs piot-env | grep "error file-not-found" > /opt/KU1T00131/flog
```

---

### Question 13: Sidecar Logging

**Task:**
Add sidecar `sdclog` (busybox) to `big-corp-app`. Run `tail -n+1 -f /var/log/big-corp-app.log`. Mount shared volume.

**Solution:**

1.  **Get existing pod YAML:**
    ```bash
    kubectl get pod big-corp-app -o yaml > pod.yaml
    ```
2.  **Edit `pod.yaml`:**
    - Add `emptyDir` volume if not present (or use existing log volume).
    - Add sidecar container:
    ```yaml
    - name: sdclog
      image: busybox
      command: ["/bin/sh", "-c", "tail -n+1 -f /var/log/big-corp-app.log"]
      volumeMounts:
        - name: log-volume # Ensure this matches the main container's volume name
          mountPath: /var/log
    ```
3.  **Replace Pod:**
    ```bash
    kubectl replace --force -f pod.yaml
    ```

---

### Question 14: High CPU Analysis

**Task:**
Find pod with label `name=overloaded-cpu` consuming most CPU. Write name to `/opt/KU7R00401.txt`.

**Solution:**

```bash
kubectl top pods -l name=overloaded-cpu --sort-by=cpu --no-headers | head -n 1 | awk '{print $1}' > /opt/KU7R00401.txt
```

---

### Question 15: Node Troubleshooting

**Task:**
Fix `wk8s-node-0` which is `NotReady`.

**Solution:**

1.  **Check Node Details:**
    ```bash
    kubectl describe node wk8s-node-0
    ```
    _Look for Conditions (e.g., KubeletStopped, DiskPressure)._
2.  **SSH into Node:**
    ```bash
    ssh wk8s-node-0
    ```
3.  **Check Kubelet Status:**
    ```bash
    systemctl status kubelet
    journalctl -u kubelet -f
    ```
4.  **Fix Issue (Common scenarios):**
    - **Stopped:** `systemctl start kubelet && systemctl enable kubelet`.
    - **Misconfigured:** Check `/var/lib/kubelet/config.yaml` or `/etc/kubernetes/kubelet.conf`.
    - **Swap On:** Turn off swap: `swapoff -a`.
