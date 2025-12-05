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

# Enable Ingress addon in Minikube (profile specific)
minikube -p cka-multinode addons enable ingress

# Create an Ingress resource imperatively with a host rule
kubectl create ingress corellian --rule="star-alliance.com/corellian/api=corellian:8080"

# Create a backend pod and service for the Ingress
kubectl run corellian-pod --image=ealen/echo-server --restart=Never --port=80 -l app=corellian
kubectl create service clusterip corellian --tcp=8080:80

# Get Ingress LoadBalancer IP using jsonpath
kubectl get ingress corellian -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Test internal service connectivity (Note: use -O- for stdout)
kubectl run tmp --image=busybox -it --rm --restart=Never -- wget -O- http://corellian:8080

# Patch Ingress Controller to use LoadBalancer (Required for Minikube Tunnel on Mac)
kubectl patch svc ingress-nginx-controller -n ingress-nginx -p '{"spec": {"type": "LoadBalancer"}}'

# Start Minikube tunnel to expose LoadBalancer IPs (Runs in background/separate terminal)
# sudo minikube tunnel -p cka-multinode

# Add local DNS mapping for Ingress host (Required for Host-based Ingress)
# echo "127.0.0.1 star-alliance.com" | sudo tee -a /etc/hosts

# Test Ingress access from local machine
curl -v -H "Host: star-alliance.com" http://127.0.0.1/corellian/api

# Create a Deployment and LoadBalancer Service in a specific namespace
kubectl create namespace external
kubectl create deploy nginx --image=nginx --replicas=3 --port=80 -n external
kubectl create service loadbalancer nginx --tcp=8080:80 -n external

# Apply a fixed deployment manifest (e.g., adding command args for index.html generation)
kubectl apply -f load-balancer-to-deployment.yaml

# Test LoadBalancer access (Round-robin verification)
for i in {1..5}; do curl http://127.0.0.1:8080; echo ""; done

# Apply custom CoreDNS configuration (e.g., rewrite rules)
kubectl apply -f coredns-custom.yaml
kubectl rollout restart deployment coredns -n kube-system

# Verify custom DNS rewrite rule (cka.example.com -> cluster.local)
kubectl run test-dns --image=busybox:1.28 -it --rm --restart=Never -- nslookup kubernetes.default.svc.cka.example.com

# Test cross-namespace access using the custom domain
kubectl run tmp-curl --image=curlimages/curl -n hello -it --rm --restart=Never -- curl -v http://nginx.external.svc.cka.example.com:8080