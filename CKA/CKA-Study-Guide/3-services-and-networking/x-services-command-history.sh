# Run a pod imperatively using a specific image and port
kubectl run echoserver-pod --image=ealen/echo-server --restart=Never --port=8080

# Get the YAML definition of a running pod
kubectl get pod echoserver-pod -o yaml

# Create a ClusterIP service mapping Service Port 80 to Target Port 8080
kubectl create service clusterip echoserver-pod --tcp=80:8080

# Run a pod and automatically create a Service for it (expose)
kubectl run echoserver-pod-expose --image=ealen/echo-server --restart=Never --port=8080 --expose

# Create a Deployment imperatively
kubectl create deploy echoserver --image=ealen/echo-server --replicas=5

# Expose a Deployment as a Service
kubectl expose deploy echoserver --port=80 --target-port=8080

# List EndpointSlices (modern replacement for Endpoints) for a specific service
kubectl get endpointslice -l kubernetes.io/service-name=echoserver

# Create a pod with a specific label
kubectl run echoserver-tcp --image=ealen/echo-server --restart=Never --port=80 -l app=echoserver-tcp

# Create a Service mapping Service Port 5005 to Target Port 80
kubectl create service clusterip echoserver-tcp --tcp=5005:80

# Update a Service's selector imperatively to match a Pod's labels
kubectl set selector service echoserver-tcp-service 'app=echoserver-tcp'

# Test connectivity from inside the cluster using a temporary busybox pod
kubectl run test-busybox --image=busybox -it --rm --restart=Never -- wget -O- <SERVICE_IP>:5005 --timeout=5

# Check listening ports inside a running container
kubectl exec echoserver-tcp -- netstat -tuln

# Create a NodePort service
kubectl create service nodeport echoserver-nodeport --tcp=5005:80

# Get the URL to access a NodePort service in Minikube
minikube service --url echoserver-nodeport