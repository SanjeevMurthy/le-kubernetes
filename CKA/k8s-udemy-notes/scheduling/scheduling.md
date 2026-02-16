
### **CKA Scheduling Concepts: Quick Revision Guide**

### 1\. `nodeName`

Forces a pod to schedule on a specific node, bypassing the scheduler entirely.
nodeName bypasses the scheduler to force a pod onto a specific node. This is a rigid approach, and if the target node is unavailable or lacks resources, the pod will get stuck in a Pending state indefinitely.

```yaml
# pod-nodename.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-manual-schedule
spec:
  containers:
  - name: nginx
    image: nginx
  # This line bypasses the scheduler and assigns the pod directly
  nodeName: worker-node-01 
```

### 2\. `nodeSelector`

Constrains the scheduler to only consider nodes that have a specific label.
nodeSelector guides the scheduler by providing a simple key-value pair. First, a label is applied to a node (e.g., disktype=ssd). Then, the pod's spec includes a nodeSelector field that matches the label. This constrains the scheduler to only place the pod on nodes with that specific label.

```yaml
# First, you would label a node like this:
# kubectl label nodes <your-node-name> disktype=ssd

# pod-nodeselector.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-with-selector
spec:
  containers:
  - name: nginx
    image: nginx
  # This tells the scheduler to only look for nodes
  # with the "disktype=ssd" label.
  nodeSelector:
    disktype: ssd
```

### 3\. `nodeAffinity`

Provides a powerful way to express complex scheduling rules, attracting pods to nodes based on labels with both "hard" (`required`) and "soft" (`preferred`) rules.
nodeAffinity provides a powerful way to express complex scheduling rules, attracting pods to nodes based on labels with both "hard" (required) and "soft" (preferred) rules

```yaml
# pod-nodeaffinity.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-with-affinity
spec:
  containers:
  - name: nginx
    image: nginx
  affinity:
    nodeAffinity:
      # "Hard" rule: Pod will NOT schedule unless this is met.
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: node-role
            operator: In
            values:
            - backend
      # "Soft" rule: Scheduler will TRY to follow this rule.
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
```

### 4\. `Taints` and `Tolerations`

Repels pods from a node. Only pods with a matching toleration are allowed to be scheduled on the tainted node, making it useful for dedicated nodes.
Taints and Tolerations work together to ensure nodes are dedicated to specific workloads. A Taint is applied to a node to repel all pods. Pods can only be scheduled on that node if they have a matching Toleration, which acts like a permission slip. This is the preferred method for creating exclusive-use nodes.


```yaml
# First, you would taint a node with an effect (NoSchedule, PreferNoSchedule, NoExecute)
# kubectl taint nodes node1 app=blue:NoSchedule

# pod-toleration.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-with-toleration
spec:
  containers:
  - name: nginx
    image: nginx
  # This "permission slip" allows the pod to ignore the taint
  # and schedule on the node.
  tolerations:
  - key: "app"
    operator: "Equal"
    value: "blue"
    effect: "NoSchedule"
```


Of course. Let's put together a complete summary of Resource Limits for your notes.

-----

### 5 Resource Requests and Limits Summary

#### 1\. The Core Idea: Requests vs. Limits

The fundamental concept is to manage how much CPU and Memory a pod can use.

  * **Requests:** The **guaranteed minimum** amount of a resource. The Kubernetes scheduler uses this value to find a node with enough capacity to run the pod.
  * **Limits:** The **absolute maximum** amount of a resource the pod is allowed to use. The kubelet on the node enforces this. If a pod exceeds its limit, it will be either throttled (CPU) or terminated (Memory - OOMKilled).

#### 2\. Quality of Service (QoS) Classes

Kubernetes uses requests and limits to assign a priority level, or QoS class, to each pod. This determines which pods get terminated first if a node runs out of resources.

  * **Guaranteed (Highest Priority):** These pods have their resource usage strictly defined. To be in this class, **requests must equal limits** for both CPU and memory in every container. These are the last pods to be killed.
  * **Burstable (Medium Priority):** These pods have a guaranteed minimum but are allowed to "burst" and use more resources up to a limit. A pod is in this class if its **requests and limits are not equal**.
  * **BestEffort (Lowest Priority):** These pods have no guarantees and run on leftover resources. A pod is in this class if it has **no requests or limits set at all**. These are the first pods to be killed.

#### 3\. Example YAML for all QoS Classes

Here’s a single file showing a pod for each class:

```yaml
# qos-examples.yaml
apiVersion: v1
kind: Pod
metadata:
  name: qos-guaranteed-pod
spec:
  containers:
  - name: guaranteed-container
    image: nginx
    resources:
      # Requests and Limits are EQUAL for this pod
      requests:
        memory: "100Mi"
        cpu: "100m"
      limits:
        memory: "100Mi"
        cpu: "100m"
---
apiVersion: v1
kind: Pod
metadata:
  name: qos-burstable-pod
spec:
  containers:
  - name: burstable-container
    image: nginx
    resources:
      # Requests and Limits are NOT EQUAL for this pod
      requests:
        memory: "100Mi"
        cpu: "100m"
      limits:
        memory: "200Mi"
        cpu: "500m"
---
apiVersion: v1
kind: Pod
metadata:
  name: qos-besteffort-pod
spec:
  containers:
  - name: besteffort-container
    image: nginx
    # NO Requests or Limits are set for this pod
    resources: {}
```

That's the perfect one-sentence summary. It captures the main job of a DaemonSet perfectly.

Here is the complete summary with a YAML example for your notes.

-----

### 6 **DaemonSet Summary**

#### 1\. The Core Idea

A **DaemonSet** is a controller that ensures a single copy of a pod runs on every node, or a specific subset of nodes, within a cluster. It's designed for cluster-wide tasks where you need an agent present on each machine.

#### 2\. Key Features & Use Cases

  * **Automatic Placement:** The DaemonSet controller automatically creates pods on new nodes that join the cluster and cleans up pods from nodes that are removed.
  * **Node Selection:** You can use a **`nodeSelector`** to restrict a DaemonSet to run only on nodes with specific labels (e.g., only on nodes with a GPU).
  * **Common Uses:** DaemonSets are ideal for running cluster-wide agents for **logging** (like Fluentd), **monitoring** (like Prometheus Node Exporter), or storage.

#### 3\. Example DaemonSet YAML

This example runs a `fluentd-elasticsearch` logging agent on every node that has the label `disktype=ssd`.

```yaml
# daemonset-example.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-elasticsearch
  namespace: kube-system
  labels:
    k8s-app: fluentd-logging
spec:
  selector:
    matchLabels:
      name: fluentd-elasticsearch
  template:
    metadata:
      labels:
        name: fluentd-elasticsearch
    spec:
      # Use a toleration to run on master nodes as well
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      containers:
      - name: fluentd-elasticsearch
        image: quay.io/fluentd_elasticsearch/fluentd:v2.5.2
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
      # This tells the DaemonSet to only run on nodes with this label
      nodeSelector:
        disktype: ssd

```


### 7 **Static Pod Summary**

#### 1\. The Core Idea

A **Static Pod** is a special type of pod managed directly by the **kubelet** on a specific node, without any intervention from the Kubernetes control plane (API server, scheduler, etc.). This makes them essential for running the control plane components themselves.

#### 2\. Key Features

  * **Kubelet-Managed:** The kubelet on a node is responsible for the entire lifecycle of a Static Pod. It watches a specific directory on the host (usually `/etc/kubernetes/manifests`), and if it sees a pod manifest file, it runs it.
  * **Control Plane Independent:** Because they don't rely on the API server or scheduler, they are used to bootstrap the cluster. The scheduler itself runs as a Static Pod.
  * **Immutable via `kubectl`:** You cannot delete or modify a Static Pod with `kubectl`. If you try, the kubelet will see that the pod is missing and immediately restart it based on the manifest file. To stop the pod, you must remove its YAML file from the kubelet's directory.

#### 3\. Example Static Pod YAML

To create this Static Pod, you would save this file inside the `/etc/kubernetes/manifests/` directory on a specific node.

```yaml
# /etc/kubernetes/manifests/static-nginx.yaml
apiVersion: v1
kind: Pod
metadata:
  name: static-nginx-pod
  labels:
    role: my-static-pod
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
```