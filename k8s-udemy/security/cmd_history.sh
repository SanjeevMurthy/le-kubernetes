alias k=kubectl
    2  echo $HOME
    3  ls /root/
    4  ls -a
    5  ls -a .kube/
    6  cat /root/.kube/config 
    7  ls 
    8  cat my-kube-config 
    9  alias k=kubectl
   10  k config --kubeconfig=/root/my-kube-config current-context
   11  k config --kubeconfig=/root/my-kube-config use-context research
   12  ls
   13  vi ~/.bashrc 
   14  source ~/.bashrc 
   15  k get pods
   16  ls /etc/kubernetes/pki/users/dev-user
   17  cat my-kube-config 
   18  vi my-kube-config 
   19  history 1  kubectl get clusterroles
    2  kubectl get clusterroles | wc -l
    3  kubectl get clusterrolebindings | wc -l
    4  kubectl api-resources --namespaced=false
    5  kubectl descrice clusterrolebinding cluster-admin
    6  kubectl describe clusterrolebinding cluster-admin
    7  kubectl describe clusterrole cluster-admin
    8  ls
    9  vi sample.yaml 
   10  kubectl apply -f sample.yaml 
   11  vi sample.yaml 
   12  vi storage-admin.yaml
   13  kubectl apply -f storage-admin.yaml 
   14  history