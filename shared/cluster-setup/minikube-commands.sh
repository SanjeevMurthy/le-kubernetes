# minikube commands

# 1. Start Minikube Tunnel
# This runs as a daemon/process that creates a network route to the cluster using the host OS.
# REQUIRED for services of type 'LoadBalancer' to get an EXTERNAL-IP on macOS.
# You usually leave this running in a separate terminal window.
# sudo privileges are often required.
minikube tunnel

# 2. Access a Service via Browser (NodePort or LoadBalancer)
# If you have a service named 'my-service' and want to open it in your default browser:
minikube service my-service
# To just get the URL without opening the browser:
minikube service my-service --url

# 3. Port Forward a specific Pod to Localhost (Quickest way to test a single Pod)
# Syntax: kubectl port-forward pod/<pod-name> <local-port>:<pod-port>
# Example: Access an Nginx pod on localhost:8080
kubectl port-forward pod/sidecar-pod 8080:80

# 4. Port Forward a Service
# Syntax: kubectl port-forward svc/<service-name> <local-port>:<service-port>
kubectl port-forward svc/my-service 8080:80

# 5. Quickly Expose a Pod as a Service
# Creates a service for a running pod (e.g., 'sidecar-pod') on port 80
kubectl expose pod sidecar-pod --type=NodePort --port=80 --name=sidecar-service
# Then access it:
minikube service sidecar-service

# 6. Get Minikube IP
# Useful if you are accessing NodePort services manually (http://<minikube-ip>:<node-port>)
minikube ip

# 7. Open Minikube Dashboard
# Opens the Kubernetes general dashboard in your browser
minikube dashboard


# add labels to pod 
kubectl label pod my-pod app=my-app


# command to create pod with label
kubectl run my-pod --image=nginx:1.21.6 --restart=Always --port=80 --name=my-pod --labels=app=my-app

# command to create pod with commands
kubectl run my-pod --image=nginx:1.21.6 --restart=Always --port=80 --name=my-pod --labels=app=my-app --command -- /bin/sh -c 'while true; do sleep 1; done'

# command to create pod with arguments
kubectl run my-pod --image=nginx:1.21.6 --restart=Always --port=80 --name=my-pod --labels=app=my-app -- /bin/sh -c 'while true; do sleep 1; done'

