kubectl get nodes
#Description: Lists all nodes in the Kubernetes cluster, showing their status, roles, age, and version.
kubectl get pods
#Description: Lists all pods in the current namespace, showing their name, status, restarts, and age.
kubectl get pods -o wide
#Description: Lists pods with additional details, including the pod's IP address and the node it is running on.
kubectl describe node <node-name>
#Description: Displays detailed information about a specific node, including its labels, taints, conditions, and running pods.
kubectl describe pod <pod-name>
#Description: Provides in-depth information about a specific pod, useful for debugging. It shows state, events, volumes, and container details.
kubectl apply -f <filename.yaml>
#Description: Creates or updates resources in the cluster from a YAML or JSON manifest file. This is a declarative way to manage objects.
kubectl taint node <node-name> key=value:Effect
#Description: Applies a 'taint' to a node. Pods that do not 'tolerate' this taint will not be scheduled on this node.
#Example Effect: NoSchedule, PreferNoSchedule, NoExecute
kubectl taint node <node-name> key:Effect-
#Description: Removes a specific taint from a node, identified by its key and effect. The trailing hyphen (-) signifies removal.
kubectl get nodes --show-labels
#Description: Lists all nodes in the cluster and includes a column displaying all of their associated labels.
kubectl label node <node-name> key=value
#Description: Adds or updates a label on a specific node. Labels are key-value pairs used for organizing and selecting resources.