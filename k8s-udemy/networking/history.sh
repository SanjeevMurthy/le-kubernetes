1  alias k=kubectl
    2  k get nodes
    3  k describe node controlplane 
    4  k get nodes -o wide
    5  ip a | grep -B2 192.168.81.3
    6  ip a 
    7  ip a | grep 192.168.31.15
    8  ip a | grep -B2  192.168.31.15
    9  k get nodes
   10  k get nodes -o wide
   11  ip a | grep -B2 192.168.31.15
   12  ip a | grep -B2 192.168.81.3
   13  ip a | grep -B2 192.168.31.15
   14  k describe node01
   15  k describe node node01
   16  ip link shop eth0
   17  ip link show eth0
   18  ssh node01
   19  k describe node controlplane 
   20  ip link
   21  ip route show default
   22  k get pods 
   23  k get pods -a
   24  k get pods -all
   25  netstat -nplt
   26  netstat -nplt | grep scheduler
   27  netstat -anp | grep etcd
   28  netstat -anp | grep etcd | grep 2381
   29  netstat -anp | grep etcd | grep 2379
     1  ip link
    2  kubectl get nodes
    3  kubectl get nodes -o wide
    4  ip addr
    5  ip addr show eth0
    6  cat /etc/kubernetes/manifests/kube-controller-manager.yaml 
    7  cat /etc/kubernetes/manifests/kube-controller-manager.yaml | grep cluster-cidr
    8  cat /etc/kubernetes/manifests/kube-apiserver.yaml 
    9  cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep cluster
   10  kubectl get pods
   11  kubectl get pods -n kube-system
   12  kubectl get pods -n kube-system | grep kube-proxy
   13  kubectl describe pods kube-proxy-7b7w2
   14  kubectl describe pods kube-proxy-7b7w2 -n kube-system
   15  kubectl describe pods kube-proxy-7b7w2 -n kube-system | grep proxy
   16  kubectl logs -n kube-system kube-proxy-7b7w2
   17  kubectl logs -n kube-system kube-proxy-7b7w2 | grep proxy
   1  k get pods
    2  k get pods -n kube-system
    3  k get svc -n kube-system
    4  k describe deployments.apps -n kube-system coredns
    5  k describe deployments.apps -n kube-system coredns | grep args
    6* k describe deployments.apps -n kube-system coredns | grep A
    7  k describe deployments.apps -n kube-system coredns | grep -i args
    8  k describe deployments.apps -n kube-system coredns | grep -iA2 args
    9  k get configmap -n kube-system
   10  k describe configmap coredns -n kube-system
   11  k get pods 
   12  k get pods -o wide
   13  k get pods -A
   14  k get svc
   15  curl web-service
   16  curl web-service:80
   17  curl http://web-service:80
   18  k get pods -A
   19  k get svc
   20  k describe svc webapp-service 
   21  k get deployments
   22  k describe deployment webapp
   23  k get svc
   24  k get pods -A
   25  k edit deployment webapp
   26  k logs deployment webapp
   27  k logs webapp-5bfb8495bf-zx6hl
   28  k logs pod  webapp-5bfb8495bf-zx6hl
   29  k logs webapp-5bfb8495bf-zx6hl -n default
   30  k edit deployment webapp
   31  k get pods -A
   32  k get svc
   33  k exec -it hr -- nslookup mysql.payroll
   34  k exec -it hr -- nslookup mysql.payroll > /root/CKA/nslookup.out
   1  k get pods -A
    2  k get deploy -A
    3  k get ingress -A
    4  k describe ingress ingress-wear-watch -n app-space
    5  k get deploy ingress-nginx-controller -n ingress-nginx -o yaml
    6  k get sv
    7  k get svc
    8  k get ingress -n app-space
    9  k describe ingress  ingress-wear-watch
   10  k describe ingress  ingress-wear-watch -n app-space
   11  k edit ingress -n app-space
   12  k edit ingress-wear-watch -n app-space
   13  k edit ingress -n app-space
   14  ls
   15  k edit ingress -n app-space
   16  k get ingress -n app-space -o yaml
   17  k get deploy -A
   18  k get svc -A
   19  k edit ingress -n app-space
   20  k get deploy -A
   21  k get svc -A
   22  vi ingress-pay.yaml
   23  k apply -f ingress-pay.yaml 
   24  k get ingress -A
   25  k edit ingress critical-space
   26  k edit ingress critical-space -n critical-space
   27  k edit ingress -n critical-space
   28  k delete ingress -n critical-sapce
   29  k delete ingress -n critical-space
   30  ls
   31  vi ingress-pay.yaml 
   32  k apply -f ingress-pay.yaml 
   33  k get ingress
   34  k get ingress -A
   35  k delete ingress ingress-wabapp-pay -n critical-space
   36  k apply -f ingress-pay.yaml
   1  kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v1.5.1" | kubectl apply -f -
    2  kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v1.5.1" | kubectl apply -f 
    3  kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v1.5.1" | kubectl apply -f -
    4  kubectl apply -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v1.6.1/deploy/crds.yaml
    5  kubectl apply -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v1.6.1/deploy/nodeport/deploy.yaml
    6  kubectl get pods -n nginx-gateway
    7  kubectl get svc -n nginx-gateway nginx-gateway -o yaml
    8  kubectl patch svc nginx-gateway -n nginx-gateway --type='json' -p='[
  {"op": "replace", "path": "/spec/ports/0/nodePort", "value": 30080},
  {"op": "replace", "path": "/spec/ports/1/nodePort", "value": 30081}
]'
    9  kubectl get svc -n nginx-gateway nginx-gateway -o yaml
   10  vi gateway.yaml
   11  kubectl apply -f gateway.yaml
   12  kubectl get gateways -n nginx-gateway
   13  kubectl describe gateway nginx-gateway -n nginx-gateway
   14  kubectl get pod,svc -n default
   15  vi frontend.yaml
   16  k apply -f gateway.yaml 
   17  k apply -f frontend.yaml 
   18  kubectl get httproute frontend-route 
   19  kubectl describe httproute frontend-route
   20  ls
   21  cat gateway.yaml