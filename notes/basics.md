## Port forwarding
`kubectl port-forward pod/nginx-pod 8080:80` forwards your local machine’s port 8080 to port 80 on the nginx-pod pod running in your Kubernetes cluster.
This lets you access the pod’s web server (Nginx) at http://localhost:8080 from your browser, even though the pod is not exposed outside the cluster.

## Minikube Port forwarding
Sometimes, Minikube needs a tunnel for NodePort/LoadBalancer services. 
`minikube tunnel`
`minikube service nginx-service`

## Pods details
`kubectl get pods -o wide`
`kubectl describe pods -n <namespace>`
`kubectl delete pod webapp`
`kubectl apply -f pod.yaml`