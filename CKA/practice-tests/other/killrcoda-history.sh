1  exit
    2  halt
    3  FILE=/ks/wait-init.sh; while ! test -f ${FILE}; do clear; sleep 0.1; done; bash ${FILE}
    4  k get pods
    5  k get nodes
    6  k get pods -n kuube-system
    7  k get pods -n kube-system
    8  ls /etc/kubernetes/manifests/
    9  vi /etc/kubernetes/manifests/kube-apiserver.yaml 
   10  k get pods -n kube-system
   11  watch crictl ps
   12  cat /var/log/pods/
   13  ls /var/log/pods/
   14  cat /var/log/pods/kube-system_kube-apiserver-controlplane_654a7bc922391f28dfd21ab63ed99c33
   15  ls /var/log/pods/kube-system_kube-apiserver-controlplane_654a7bc922391f28dfd21ab63ed99c33
   16  ls /var/log/pods/kube-system_kube-apiserver-controlplane_654a7bc922391f28dfd21ab63ed99c33/kube-apiserver/
   17  cat /var/log/pods/kube-system_kube-apiserver-controlplane_654a7bc922391f28dfd21ab63ed99c33/kube-apiserver/4.log 
   18  ls /var/log/containers/kube-apiserver-controlplane_kube-system_kube-apiserver-9dd440d746aae5b3e22e204c23edbba93ecaaf38bb5371f52fd9f1713d75f277.log 
   19  cat /var/log/containers/kube-apiserver-controlplane_kube-system_kube-apiserver-9dd440d746aae5b3e22e204c23edbba93ecaaf38bb5371f52fd9f1713d75f277.log 
   20  vi /etc/kubernetes/manifests/kube-apiserver.yaml 
   21  k get pods -n kube-system
   22  clear
   23  vi /etc/kubernetes/manifests/kube-apiserver.yaml 
   24  cat /var/log/containers/kube-apiserver-controlplane_kube-system_kube-apiserver-9dd440d746aae5b3e22e204c23edbba93ecaaf38bb5371f52fd9f1713d75f277.log 
   25  cat /var/log/containers
   26  ls /var/log/containers/
   27  cat /var/log/containers/kube-apiserver-controlplane_kube-system_kube-apiserver-742b964c2e980d5af58e8e1d25fbc10db5797e870d043394b6b7cf63d07c8cbb.log
   28  clear
   29  crictl logs
   30  crictl ps
   31  vi /etc/kubernetes/manifests/kube-apiserver.yaml 
   32  crictl ps
   33  crictl logs
   34  vi /etc/kubernetes/manifests/kube-apiserver.yaml 
   35  k get pods -n kube-system
   36  cd /var/log/pods/
   37  ls
   38  cd kube-system_kube-apiserver-controlplane_5291f611ac528da20fd1b7abe3701a40
   39  ls
   40  cd kube-apiserver/
   41  ls
   42  cd ..
   43  cd containers/
   44  ls
   45  ls | grep api
   46  ls | grep dns
   47  vi /etc/kubernetes/manifests/kube-apiserver.yaml 
   48  ls | grep api
   49  journalctl -u kube-apiserver
   50  journalctl -u kube
   51  journalctl -u kubelet
   52  clear
   53  tail -f /var/log/syslog | grep apiserver
   54  journalctl | grep apiserver
   55  history
       1  exit
    2  halt
    3  FILE=/ks/wait-init.sh; while ! test -f ${FILE}; do clear; sleep 0.1; done; bash ${FILE}
    4  k get nodes
    5  k get pods -n kube-system
    6  cd /var/log/containers/
    7  ls
    8  ls | grep api
    9  journalctl | grep apiserver
   10  journalctl | grep apiserver | grep error
   11  journalctl | grep apiserver | grep err
   12  vi /etc/kubernetes/manifests/kube-apiserver.yaml 
   13  journalctl | grep apiserver | grep err
   14  clear
   15  journalctl | grep apiserver | grep err
   16  crictl ps
   17  crictl logs
   18  vi /etc/kubernetes/manifests/kube-apiserver.yaml 
   19  ls
   20  cat kube-apiserver-controlplane_kube-system_kube-apiserver-d2c0e511539690107f4399ac561346d1e03a65c643944e7f84952b428d0ed1bf.log
   21  vi /etc/kubernetes/manifests/kube-apiserver.yaml 
   22  cat kube-apiserver-controlplane_kube-system_kube-apiserver-d2c0e511539690107f4399ac561346d1e03a65c643944e7f84952b428d0ed1bf.log
   23  ls
   24  clear
   25  ls
   26  ls | api
   27  ls | grep api
   28  cat kube-apiserver-controlplane_kube-system_kube-apiserver-55be31b78d80e9e18d8c51b91ac1fc17c17f317051b7a226b47bd3834cca86e4.log
   29  clear
   30  ls
   31  cat kube-apiserver-controlplane_kube-system_kube-apiserver-55be31b78d80e9e18d8c51b91ac1fc17c17f317051b7a226b47bd3834cca86e4.log
   32  cat kube-apiserver-controlplane_kube-system_kube-apiserver-063e3db82c068f3e2e5e9b1b3413d9b5131a00e251f4fa156451e084053a954e.log
   33  cat kube-apiserver-controlplane_kube-system_kube-apiserver-063e3db82c068f3e2e5e9b1b3413d9b5131a00e251f4fa156451e084053a954e.log | grep Err
   34  vi /etc/kubernetes/manifests/kube-apiserver.yaml 
   35  ps -lntp | grep etcd
   36  ps -aux | grep etcd
   37  crictl ps | grep etcd
   38  crictl logs ce915253b6d0d
   39  clear
   40  systemctl status etcd
   41  journalctl -u etcd -f
   42  journalctl -u etcd 
   43  ss -lntp | grep etcd
   44  netstat -lntp | grep etcd
   45  vi /etc/kubernetes/manifests/kube-apiserver.yaml 
   46  ls | grep api
   47  ls
   48  cat kube-apiserver-controlplane_kube-system_kube-apiserver-8256542c052f8f03879858b7c9eea414f3f2d36b77d2e8f3c22ff976be6a6c0b.log
   49  vi /etc/kubernetes/manifests/kube-apiserver.yaml 
   50  cat kube-apiserver-controlplane_kube-system_kube-apiserver-8256542c052f8f03879858b7c9eea414f3f2d36b77d2e8f3c22ff976be6a6c0b.log
   51  k get nodes
   52  cat kube-apiserver-controlplane_kube-system_kube-apiserver-8256542c052f8f03879858b7c9eea414f3f2d36b77d2e8f3c22ff976be6a6c0b.log
   53  cat kube-apiserver-controlplane_kube-system_kube-apiserver-8256542c052f8f03879858b7c9eea414f3f2d36b77d2e8f3c22ff976be6a6c0b.log | grep err
   54  ls
   55  cat kube-apiserver-controlplane_kube-system_kube-apiserver-43e1ec55cbdde99018df6405f29514a94ad4b10749300c84e3e8c3163ff5f761.log | grep err
   56  vi /etc/kubernetes/manifests/kube-apiserver.yaml 
   57  clear
   58  ls
   59  clear
   60  vi /etc/kubernetes/manifests/kube-apiserver.yaml 
   61  cd /etc/kubernetes/manifests/
   62  ls
   63  mv kube-apiserver.yaml /etc/kubernetes/
   64  watch crictl ps
   65  service kubelet restart
   66  mv /etc/kubernetes/kube-apiserver.yaml .
   67  ls
   68  clear
   69  service kubelet restart
   70  watch crictl ps
   71  history
    1  exit
    2  halt
    3  FILE=/ks/wait-init.sh; while ! test -f ${FILE}; do clear; sleep 0.1; done; bash ${FILE}
    4  k get nodes
    5  k get pods -n kube-system
    6  k describe kube-controller-manager-controlplane -n kube-system
    7  k logs kube-controller-manager-controlplane -n kube-system
    8  clear
    9  kubectl logs -n kube-system kube-controller-manager-controlplane
   10  ls /var/log/pods
   11  cat /var/log/pods/kube-system_kube-controller-manager-controlplane_434f219502bb1c1b46f4124ca5c3ae5b
   12  ls /var/log/pods/kube-system_kube-controller-manager-controlplane_434f219502bb1c1b46f4124ca5c3ae5b/kube-controller-manager/
   13  cat /var/log/pods/kube-system_kube-controller-manager-controlplane_434f219502bb1c1b46f4124ca5c3ae5b/kube-controller-manager/5.log 
   14  cat /var/log/pods/kube-system_kube-controller-manager-controlplane_434f219502bb1c1b46f4124ca5c3ae5b/kube-controller-manager/5.log } grep error
   15  cat /var/log/pods/kube-system_kube-controller-manager-controlplane_434f219502bb1c1b46f4124ca5c3ae5b/kube-controller-manager/5.log |  grep error
   16  clear
   17  cat /var/log/pods/kube-system_kube-controller-manager-controlplane_434f219502bb1c1b46f4124ca5c3ae5b/kube-controller-manager/5.log |  grep error
   18  cat /var/log/pods/kube-system_kube-controller-manager-controlplane_434f219502bb1c1b46f4124ca5c3ae5b/kube-controller-manager/5.log |  grep err
   19  clear
   20  cat /var/log/pods/kube-system_kube-controller-manager-controlplane_434f219502bb1c1b46f4124ca5c3ae5b/kube-controller-manager/5.log |  grep "Error"
   21  cat /etc/kubernetes/manifests/kube-controller-manager.yaml 
   22  cat /etc/kubernetes/manifests/kube-controller-manager.yaml | grep "--project-sidecar-insertion"
   23  cat /etc/kubernetes/manifests/kube-controller-manager.yaml | grep "insertion"
   24  vi /etc/kubernetes/manifests/kube-controller-manager.yaml
   25  k get pods -n kube-system
   26  cat /var/log/pods/kube-system_kube-controller-manager-controlplane_434f219502bb1c1b46f4124ca5c3ae5b/kube-controller-manager/5.log |  grep "Error"
   27  cat /var/log/pods/kube-system_kube-controller-manager-controlplane_434f219502bb1c1b46f4124ca5c3ae5b/kube-controller-manager
   28  cd /var/log/pods/kube-system_kube-controller-manager-controlplane_a9d904d28a911d35f3dde7c233902499/
   29  ls
   30  cd kube-controller-manager/
   31  ls
   32  cat 0.log 
   33  cat 0.log | grep "Error"
   34  watch crictl ps
   35  clear
   36  history
   1  exit
    2  halt
    3  clear
    4  cat /var/log/syslog | grep "Error"
    5  cat /var/log/syslog | grep "kubelet"
    6  cd /etc/kubernetes/
    7  ls
    8  clear
    9  cat kubelet.conf 
   10  cat /var/lib/kubelet/config.yaml 
   11  journalctl -u kubelet
   12  clear
   13  ls
   14  cd manifests/
   15  ls
   16  cd ..
   17  clear
   18  cat kubelet.conf 
   19  service kubelet status
   20  echo $KUBELET_KUBECONFIG_ARGS
   21  cat /var/log/syslog | grep kubelet
   22  find / | grep kubeadm
   23  cat /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
   24  cat /var/lib/kubelet/kubeadm-flags.env
   25  ls
   26  find / | grep kubelet
   27  lear
   28  clear
   29  cat /var/lib/kubelet/kubeadm-flags.env
   30  vi /var/lib/kubelet/kubeadm-flags.env
   31  service kubelet start
   32  service kubelet status
   33  history
   k config get-contexts
    4  k config current-context
    5  k config use-context kubernetes-admin@kubernetes
    6  k get pods
    7  k logs alpine-reader-pod | egrep 'INFO|ERROR'
    8  k logs alpine-reader-pod | grep 'INFO|ERROR'
    9  k logs alpine-reader-pod | egrep 'INFO|ERROR'
   10  k logs alpine-reader-pod | egrep 'INFO|ERROR' > podlogs.txt
   11  history
   kubectl create clusterrolebinding kubernetes-admin-binding \
  --clusterrole=cluster-admin \
  --user=kubernetes-admin

1  exit
    2  halt
    3  k config get-contexts
    4  k config use-context kubernetes-admin@kubernetes 
    5  k get secrets -n database-ns
    6  alias ns="-n database-ns"
    7  k describe secret ns
    8  ns
    9  k describe secret databse-data ns
   10  k ns describe secret database-data
   11  clear
   12  k describe secret database-data -n database-ns
   13  NS="-n database-ns"
   14  k describe secret database-data $NS
   15  k get secret database-data $NS
   16  k get secret database-data $NS -o yaml
   17  k get secret database-data $NS -o json
   18  k get secret database-data $NS -o jsonpath='{.data.DB_PASSWORD}'
   19  k get secret database-data $NS -o jsonpath='{.data.DB_PASSWORD}' > decoded.txt
   20  k get secret database-data $NS -o jsonpath='{.data}' > decoded.txt
   21  ls
   22  cat decoded.txt 
   23  k get secret database-data $NS -o jsonpath='{.data.DB_PASSWORD}' | base64 --decode > decoded.txt
   24  clear
   25  k get secret database-data $NS -o jsonpath='{.data.DB_PASSWORD}' | base64 --decode > decoded.txt
   26  ls
   27  cat decoded.txt 
   28  history
   3  k config get-contexts 
    4  k get deploy
    5  k expose deploy nginx-deployment --name=nginx-service --port=8080 --target-port=80 --type="ClusterIP"
    6  k get svc
    7  k describe svc nginx-service
    8  k describe svc nginx-service -o json
    9  k get svc nginx-service -o json
   10  k get deployments nginx-deployment -o json
   11  k describe deploy nginx-deployment 
   12  clear
   13  k get svc nginx-service -o json
   14  k get svc nginx-service 
   15  k describe svc nginx-service -o json
   16  clear
   17  k describe service nginx-service 
   18  k describe service nginx-service | grep endpoint
   19  k describe service nginx-service | grep endpoints
   20  k describe service nginx-service | grep -i endpoints
   21  k get pods -l app=nginx-app
   22  k get pods -l app=nginx-app -o jsonpath='{.items[*].status.podIP}'
   23  k get pods -l app=nginx-app -o jsonpath='{.items[*].status.podIP}{"\n"}'
   24  kubectl get pods -l app=nginx-app -o jsonpath='{range .items[*]}{.status.podIP}{"\n"}{end}' | sort -V
   25  kubectl get pods -l app=nginx-app -o jsonpath='{range .items[*]}{.status.podIP}{"\n"}' 
   26  kubectl get pods -l app=nginx-app -o jsonpath='{range .items[*]}{.status.podIP}' 
   27  kubectl get pods -l app=nginx-app -o jsonpath='{range .items[*]}{"\n"}' 
   28* kubectl get pods -l app=nginx-app -o jsonpath='{range .items[*]}{}'
   29  kubectl get pods -l app=nginx-app -o jsonpath='{range .items[*]}{.status.podIP}{"\n"}{end}' 
   30  echo "IP_ADDRESS" >> pod_ips.txt
   31  kubectl get pods -l app=nginx-app -o jsonpath='{range .items[*]}{.status.podIP}{"\n"}{end}' >> pod_ips.txt 
   32  cat pod_ips.txt 
   33  kubectl get pods -l app=nginx-app -o jsonpath='{range .items[*]}{.status.podIP}{"\n"}{end}' | sort -V >> pod_ips.txt 
   34  cat pod_ips.t