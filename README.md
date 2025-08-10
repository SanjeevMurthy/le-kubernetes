# le-kubernetes

k get pods -n kube-system


# Taints and Toleration
Taint set on node level
Toleration set on Pod level


k describe node controlplane | grep Taint
Taints:             node-role.kubernetes.io/control-plane:NoSchedule