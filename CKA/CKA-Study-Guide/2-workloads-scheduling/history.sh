# Alias 'k' to 'kubectl' for easier command entry
alias k=kubectl

# List all nodes in the cluster to verify cluster status
k get nodes

# Create a deployment named 'nginx' using image 'nginx:1.17.0' with 2 replicas
k create deployment nginx --image=nginx:1.17.0 --replicas=2

# List all deployments in the current namespace
k get deployments

# List all pods in the current namespace
k get pods

# Scale the 'nginx' deployment to 7 replicas
k scale deployment nginx --replicas=7

# Delete a specific pod (replace <pod-name> with the actual pod name)
# This is often done to test self-healing or restart behavior
k delete pod <pod-name>

# Scale the 'nginx' deployment down to 3 replicas
k scale deployment nginx --replicas=3

# Create a Horizontal Pod Autoscaler (HPA) for 'nginx'
# Target 65% CPU utilization, with a minimum of 3 and maximum of 10 replicas
k autoscale deployment nginx --cpu-percent=65 --min=3 --max=10

# List all Horizontal Pod Autoscalers in the current namespace
k get hpa

# Display detailed information about the 'nginx' HPA
k describe hpa nginx

# Display resource (CPU/Memory) usage for nodes (requires metrics-server)
k top nodes

# Display resource (CPU/Memory) usage for pods (requires metrics-server)
k top pods

# Delete the 'nginx' HPA
k delete hpa nginx

# Edit the 'nginx' deployment configuration in the default text editor
k edit deployment nginx

# Get the YAML configuration of all deployments (or a specific one if named)
k get deployment -o yaml

# Export the YAML configuration of deployments to a file named 'nginx-deployment.yaml'
k get deployment -o yaml > nginx-deployment.yaml

# Delete the 'nginx' deployment
k delete deployment nginx

# Apply configuration from the file 'deployment-scale.yaml'
k apply -f deployment-scale.yaml

# Apply configuration from the file 'hpa-for-deployment.yaml'
k apply -f hpa-for-deployment.yaml

# Display detailed information about the 'nginx-hpa' HPA
k describe hpa nginx-hpa

# Delete resources defined in the file 'hpa-for-deployment.yaml'
k delete -f hpa-for-deployment.yaml

# View the rollout history of the 'nginx' deployment
k rollout history deploy/nginx

# Update the image of the 'nginx' deployment to 'nginx:1.21.1' and record the command in history
k set image deploy/nginx nginx=nginx:1.21.1 --record

# Update the image of the 'nginx' deployment to 'nginx:1.21.1' (without recording)
k set image deploy/nginx nginx=nginx:1.21.1

# List deployments with additional information (e.g., images, selectors)
k get deployment -o wide

# Undo the last rollout of the 'nginx' deployment, reverting to revision 1
k rollout undo deploy/nginx --to-revision=1

# Undo the rollout of the 'nginx' deployment, reverting to revision 3
k rollout undo deploy/nginx --to-revision=3

# Check the status of the rollout for the 'nginx' deployment
k rollout status deploy/nginx

# Apply configuration from the file 'secret-generic.yaml'
k apply -f secret-generic.yaml

# List all secrets in the current namespace
k get secret

# Display detailed information about the 'basic-auth' secret
k describe secret basic-auth

# Execute an interactive bash shell inside a specific pod (replace <pod-name>)
k exec -it <pod-name> -- bash

# Get the volume names used by a specific pod using JSONPath (replace <pod-name>)
k get pod <pod-name> -o jsonpath='{.spec.volumes[*].name}'

# List all pods and display their names and volume names using custom columns
k get pods -o custom-columns=NAME:.metadata.name,VOLUMES:.spec.volumes[*].name