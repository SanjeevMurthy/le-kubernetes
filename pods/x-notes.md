## Port forwarding
`kubectl port-forward pod/nginx-pod 8080:80` forwards your local machine’s port 8080 to port 80 on the nginx-pod pod running in your Kubernetes cluster.
This lets you access the pod’s web server (Nginx) at http://localhost:8080 from your browser, even though the pod is not exposed outside the cluster.

## Minikube Port forwarding
Sometimes, Minikube needs a tunnel for NodePort/LoadBalancer services. 
`minikube tunnel`
`minikube service nginx-service`

## Pods details
`kubectl get all`
`kubectl get pods -o wide`
`kubectl describe pods -n <namespace>`
`kubectl delete pod webapp`
`kubectl apply -f pod.yaml`


## Commands 
Create an NGINX Pod
`kubectl run nginx --image=nginx`

Generate POD Manifest YAML file (-o yaml). Don't create it(--dry-run)
`kubectl run nginx --image=nginx --dry-run=client -o yaml`



## Deployment
Create a deployment
`kubectl create deployment --image=nginx nginx`

Generate Deployment YAML file (-o yaml). Don't create it(--dry-run)
`kubectl create deployment --image=nginx nginx --dry-run=client -o yaml`

Generate Deployment with 4 Replicas
`kubectl create deployment nginx --image=nginx --replicas=4`

You can also scale a deployment using the kubectl scale command.
`kubectl scale deployment nginx --replicas=4`

Another way to do this is to save the YAML definition to a file and modify
`kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > nginx-deployment.yaml`
You can then update the YAML file with the replicas or any other field before creating the deployment.

## Service
Create a Service named redis-service of type ClusterIP to expose pod redis on port 6379
`kubectl expose pod redis --port=6379 --name redis-service --dry-run=client -o yaml`
(This will automatically use the pod's labels as selectors)

Or

`kubectl create service clusterip redis --tcp=6379:6379 --dry-run=client -o yaml` 
(This will not use the pods labels as selectors, instead it will assume selectors as app=redis. You cannot pass in selectors as an option. So it does not work very well if your pod has a different label set. So generate the file and modify the selectors before creating the service)



Create a Service named nginx of type NodePort to expose pod nginx's port 80 on port 30080 on the nodes:

`kubectl expose pod nginx --type=NodePort --port=80 --name=nginx-service --dry-run=client -o yaml`
(This will automatically use the pod's labels as selectors, but you cannot specify the node port. You have to generate a definition file and then add the node port in manually before creating the service with the pod.)

Or

`kubectl create service nodeport nginx --tcp=80:80 --node-port=30080 --dry-run=client -o yaml`

(This will not use the pods labels as selectors)
Both the above commands have their own challenges. While one of it cannot accept a selector the other cannot accept a node port. I

 would recommend going with the kubectl expose command. If you need to specify a node port, generate a definition file using the same command and manually input the nodeport before creating the service.



`k run redis --image=redis --namespace=finance`


## Accessing Pods and Service from outside
`minikube service nginx-service --url`
Minikube:
Retrieves the cluster IP and NodePort for your Service.
Spawns a lightweight tunnel process (an SSH-style port-forward) from your host’s loopback to <clusterIP>:<nodePort>.
Prints a URL like http://127.0.0.1:XXXXX that you can open in your browser.
Keep that terminal open (it’s running the tunnel); Ctrl-C to tear it down and clean up the routes 

*minikube tunnel* is only for Services of type LoadBalancer, where Minikube emulates a cloud LB by adding routes on your host.
minikube service … --url already does a targeted port-forward for NodePort Services on drivers that aren’t natively reachable.
You could alternatively use
`kubectl port-forward svc/nginx-service 8080:80`