
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