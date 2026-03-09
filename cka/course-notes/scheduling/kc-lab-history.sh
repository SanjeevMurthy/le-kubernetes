1  alias kgp="kubectl get pods"
    2  alias k=kubectl
    3  k get nodes
    4  k get taint
    5  k describe node01
    6  k describe node node01
    7  k taint node01 spray=mortein:NoSchedule
    8  k taint node node01 spray=mortein:NoSchedule
    9  k create pod -h
   10  vi pod.yaml
   11  k apply -f pod.yaml 
   12  kgp mosquito
   13  k describe pod mosquito
   14  cp pod.yaml bee-pod.yaml
   15  ls
   16  vi bee-pod.yaml 
   17  k apply -f bee-pod.yaml 
   18  vi bee-pod.yaml 
   19  k apply -f bee-pod.yaml 
   20  vi bee-pod.yaml 
   21  k apply -f bee-pod.yaml 
   22  vi bee-pod.yaml 
   23  k apply -f bee-pod.yaml 
   24  vi bee-pod.yaml 
   25  kgp
   26  kgp -all
   27  kgp -h
   28  k describe pod bee
   29  k describe nodes
   30  k describe node controlplane
   31  k taint nodes controlplane node-role.kubernetes.io/control-plane:NoSchedule-
   32  kgp
   33  k describe pod mosquito
   34  history
   1  alias k=kubectl
    2  k describe nodes node01
    3  k get nodes --show-labels
    4  k get nodes node01 --show-labels
    5  k label nodes node01 color=blue
    6  ls
    7  cat sample.yaml 
    8  vi sample.yaml 
    9  k apply -f sample.yaml 
   10  vi sample.yaml 
   11  k apply -f sample.yaml 
   12  cat sample.yaml 
   13  k get nodes
   14  k describe node01
   15  k describe node node01
   16  k describe node controlplane
   17  k get nodes --show-labels
   18  ls
   19  vi sample.yaml 
   20  k apply -f sample.yaml 
   21  vi sample.yaml 
   22  k apply -f sample.yaml 
   23  k get pods --show-nodes
   24  k get pods
   25  k get pods -o wide
   26  vi sample.yaml 
   27  cp sample.yaml red.yaml
   28  vi red.yaml 
   29  k apply -f red.yaml 
   30  vi red.yaml 
   31  k apply -f red.yaml 
   32  history
   1  alias k=kubectl
    2  k describe pod rabbit
    3  k get pods
    4  k delete pod rabbit
    5  k get pods
    6  k get pods
    7  k describe pod elephant
    8  k describe pod elephant
    9  k get pods
   10  kubectl describe pod elephant | grep -A5 "Last State"
   11  ls
   12  cat sample.yaml 
   13  vi sample.yaml 
   14  cat sample.yaml 
   15  k get pods
   16  k delete pod elephant
   17  k apply -f sample.yaml 
   18  k describe pod elephant
   19  kubectl describe pod elephant | grep -A5 "Last State"
   20  k describe pod elephant
   21  k get pods
   22  kubectl describe pod elephant_default --namespace default
   23  kubectl describe pod elephant --namespace default
   24  kubectl logs elephant -c mem-stress --namespace default
   25  kubectl get events --namespace default --sort-by='.lastTimestamp'
   26  k get pods
   27  k delete pod elephant
   1  alias k=kubectl
    2  k get deamonsets
    3  k get daemonsets
    4  k get daemonsets --all
    5  k get daemonsets --all-namespaces 
    6  k get daemonsets kube-proxy
    7  k get daemonset kube-proxy
    8  k describe daemonset kube-proxy --namespace=kube-system
    9  k describe daemonset kube-flannel-ds --namespace=kube-flannel
   10  ls
   11  cat sample.yaml 
   12  vi sample.yaml 
   13  k create deployment elasticsearch --image=registry.k8s.io/fluentd-elasticsearch:1.20 -n kube-system --dry-run=client -o yaml > fluentd.yaml
   14  ls
   15  cat fluentd.yaml 
   16  vi fluentd.yaml 
   17  k create -f fluentd.yaml 
   18  history
   1  alias k=kubectl
    2  k get priorityclasses
    3  k get priorityclasses -n default
    4  ls
    5  kubectl create priorityclass high-priority   --value=1000000   --description="This priority class is for critical workloads"   --dry-run=client -o yaml
    6  ls
    7  vi pc.yaml
    8  k create -f pc.yaml 
    9  vi pc.yaml 
   10  k apply -f pc.yaml 
   11  k get priorityclasses
   12  k delete priorityclasses.scheduling.k8s.io high-priority
   13  k apply -f pc.yaml 
   14  vi lpc.yaml
   15  k apply -f lpc.yaml 
   16  vi lpp.yaml
   17  k apply -f lpp.yaml 
   18  vi lpp.yaml 
   19  rm lpp.yaml 
   20  vi lpp.yaml
   21  ls
   22  vi lpp.yaml
   23  k apply -f lpp.yaml 
   24  rm lpp.yaml 
   25  vi lpp.yaml
   26  k apply -f lpp.yaml 
   27  vi hpp.yaml
   28  k apply -f hpp.yaml 
   29  kubectl get pods -o custom-columns="NAME:.metadata.name,PRIORITY:.spec.priorityClassName"
   30  k get pods
   31  kubectl describe pod critical-app
   32  k get pod critical-app -o yaml
   33  k get pod critical-app -o yaml | k neat
   34  k get pod critical-app -o yaml | kubectl neat
   35  k get pod critical-app -o yaml | jq 'del(.metadata.managedFields, .metadata.uid, .metadata.resourceVersion, .metadata.creationTimestamp, .status)'
   36  k get pod critical-app -o yaml 
   37  k delete critical-app
   38  k delete pod critical-app
   39  vi critical-pod.yaml
   40  k apply -f critical-pod.yaml 
   41  history
   1  alias k=kubernetes
    2  k get pods -n kube-system
    3  alias k=kubectl
    4  k get pods -n kube-system
    5  k describe pod kube-scheduler-controlplane
    6  k describe pod kube-scheduler-controlplane -n kube-system
    7  k get serviceaccount my-scheduler
    8  k get serviceaccount -n kube-system
    9  k get clusterrolebinding
   10  ls
   11  cat my-scheduler-configmap.yaml 
   12  cat my-scheduler-config.yaml 
   13  k apply -f my-scheduler-configmap.yaml 
   14  ls
   15  cat my-scheduler
   16  cat my-scheduler.yaml 
   17  kubectl describe pod kube-scheduler-controlplane --namespace=kube-system
   18  k apply -f my-scheduler.yaml 
   19  vi my-scheduler.yaml 
   20  k apply -f my-scheduler.yaml 
   21  cat my-scheduler.yaml 
   22  ls
   23  cat nginx-pod.yaml 
   24  vi nginx-pod.yaml 
   25  k apply -f nginx-pod.yaml 
   26  k get pod