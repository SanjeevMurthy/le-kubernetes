1  alias k=kubectl
    2  k get pods
    3  k get rs
    4  k get rs
    5  k describe rs new-replica-set
    6  k describe pod new-replica-set-62r6c
    7  k delete new-replica-set-62r6c
    8  k delete pod new-replica-set-62r6c
    9  k get rs
   10  ls
   11  cat replicaset-definition-1.yaml 
   12  k apply -f replicaset-definition-1.yaml 
   13  vi replicaset-definition-1.yaml 
   14  k apply -f replicaset-definition-1.yaml 
   15  k api-resources | grep replicaset
   16  k explain replicaset | grep VERSION
   17  k explain replicaset
   18  vi replicaset-definition-1.yaml 
   19  k apply -f replicaset-definition-1.yaml 
   20  k apply -f replicaset-definition-2.yaml 
   21  vi replicaset-definition-2.yaml 
   22  k apply -f replicaset-definition-2.yaml 
   23  k delete rs replicaset-1
   24  k delete rs replicaset-2
   25  k get rs
   26  k edit rs new-replica-set 
   27  k get rs
   28  k get rs
   29  k edit rs new-replica-set 
   30  clear
   31  k get rs
   32  k get pods
   33  k delete pods --all
   34  k get pods
   35  k scale rs --replicas=5
   36  k scale rs new-replica-set --replicas=5
   37  k get pods
   38  history