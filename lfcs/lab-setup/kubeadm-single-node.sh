#!/usr/bin/env bash
# Turn the LFCS Ubuntu VM into a single-node kubeadm cluster.
#
# Why this exists: the CKS question bank needs a root shell on a real node for
# 26 of its 44 questions, and Killercoda hands you one for an hour at a time.
# This VM already exists for LFCS, so it can carry a cluster you own and can
# leave broken overnight.
#
# This is optional and is not needed for any LFCS question.
#
# Run as root inside lfcs-ubuntu, with its RAM raised to 6 GB first:
#   sudo bash lfcs/lab-setup/kubeadm-single-node.sh
#
# Override the Kubernetes minor version if the exam has moved on:
#   sudo K8S_MINOR=v1.36 bash lfcs/lab-setup/kubeadm-single-node.sh
#
# CALICO_VERSION and POD_CIDR are overridable the same way. Both defaults were
# current when this was written; check them if the build fails on a fetch.
set -euo pipefail

K8S_MINOR="${K8S_MINOR:-v1.35}"
CALICO_VERSION="${CALICO_VERSION:-v3.28.2}"
POD_CIDR="${POD_CIDR:-10.244.0.0/16}"

[[ $EUID -eq 0 ]] || { echo "run as root: sudo bash $0" >&2; exit 1; }

# The same guard the practice CLI uses. A kubeadm init on a machine that is not
# a throwaway lab is not something to do by accident.
if [[ ! -f /etc/lfcs-lab ]]; then
  echo "This host has no /etc/lfcs-lab marker, so it is not a lab VM." >&2
  echo "Provision it first with lfcs/lab-setup/provision-ubuntu.sh." >&2
  exit 1
fi
if ! grep -qi ubuntu /etc/os-release; then
  echo "This script targets the Ubuntu VM. Rocky is the secondary LFCS host." >&2
  exit 1
fi
if [[ -f /etc/kubernetes/admin.conf ]]; then
  echo "A cluster already exists here (/etc/kubernetes/admin.conf)." >&2
  echo "To rebuild it: kubeadm reset -f && rm -rf /etc/cni/net.d ~/.kube" >&2
  exit 1
fi

# The host-only network is 192.168.56.0/24, so the pod network must not be
# Calico's 192.168.0.0/16 default or pod traffic and lab traffic collide.
case "$POD_CIDR" in
  192.168.*) echo "POD_CIDR $POD_CIDR overlaps the lab network 192.168.56.0/24." >&2; exit 1 ;;
esac

RAM_MB=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
if [[ "$RAM_MB" -lt 5000 ]]; then
  echo "This VM has ${RAM_MB} MB of RAM. A single-node cluster wants about 6 GB." >&2
  echo "Raise it in VirtualBox first, or export ALLOW_SMALL_RAM=1 to try anyway." >&2
  [[ "${ALLOW_SMALL_RAM:-0}" == 1 ]] || exit 1
fi

echo "== kernel modules and sysctl =="
printf 'overlay\nbr_netfilter\n' > /etc/modules-load.d/k8s.conf
modprobe overlay
modprobe br_netfilter
cat > /etc/sysctl.d/99-kubernetes.conf <<'EOF'
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system >/dev/null

echo "== container runtime =="
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y -q containerd apt-transport-https ca-certificates curl gpg
mkdir -p /etc/containerd
[[ -s /etc/containerd/config.toml ]] || containerd config default > /etc/containerd/config.toml
# kubelet uses the systemd cgroup driver; containerd must agree or kubelet
# restarts in a loop with no useful message.
sed -i 's/^\(\s*SystemdCgroup\s*=\s*\)false/\1true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd >/dev/null

echo "== kubernetes packages ($K8S_MINOR) =="
mkdir -p /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/$K8S_MINOR/deb/Release.key" |
  gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg --yes
cat > /etc/apt/sources.list.d/kubernetes.list <<EOF
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$K8S_MINOR/deb/ /
EOF
apt-get update -q
apt-get install -y -q kubelet kubeadm kubectl
# Hold them: an unplanned upgrade of kubelet is its own CKS question, not a
# surprise you want on a Tuesday.
apt-mark hold kubelet kubeadm kubectl >/dev/null

echo "== cluster =="
# Swap stays on. This VM also hosts the LFCS swap question, and turning swap off
# permanently would break it. kubelet is told to tolerate swap instead, which is
# also closer to what modern clusters do.
cat > /tmp/kubeadm-lab.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
networking:
  podSubnet: $POD_CIDR
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
failSwapOn: false
EOF
kubeadm init --config /tmp/kubeadm-lab.yaml --ignore-preflight-errors=Swap,Mem
rm -f /tmp/kubeadm-lab.yaml

export KUBECONFIG=/etc/kubernetes/admin.conf
mkdir -p /root/.kube && cp -f /etc/kubernetes/admin.conf /root/.kube/config
if id lfcs >/dev/null 2>&1; then
  install -d -o lfcs -g lfcs -m 700 /home/lfcs/.kube
  install -o lfcs -g lfcs -m 600 /etc/kubernetes/admin.conf /home/lfcs/.kube/config
fi

echo "== networking (Calico, for NetworkPolicy) =="
# create, not apply: the operator manifest's CRDs exceed the annotation size
# limit that apply uses to store its last-applied configuration.
kubectl create -f "https://raw.githubusercontent.com/projectcalico/calico/$CALICO_VERSION/manifests/tigera-operator.yaml"
cat <<EOF | kubectl create -f -
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
      - blockSize: 26
        cidr: $POD_CIDR
        encapsulation: VXLANCrossSubnet
        natOutgoing: Enabled
        nodeSelector: all()
---
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}
EOF

echo "== one node means it must schedule its own pods =="
kubectl taint nodes --all node-role.kubernetes.io/control-plane- 2>/dev/null || true

echo ""
echo "Waiting for the node to become Ready (Calico takes a couple of minutes)..."
kubectl wait --for=condition=Ready node --all --timeout=300s || {
  echo "The node is not Ready yet. Watch it with: kubectl get pods -A -w" >&2
  exit 1
}

echo ""
echo "Done."
kubectl get nodes -o wide
echo ""
echo "  kubeconfig:  /root/.kube/config, and /home/lfcs/.kube/config if that user exists"
echo "  pod network: $POD_CIDR, Calico, so NetworkPolicy questions work"
echo "  swap:        left on, because the LFCS swap question needs it"
echo ""
echo "For the CKS bank, from the repository:"
echo "  cd cks/practice-cli && sudo bash tools/install-tools.sh all && ./cks --env"
echo ""
echo "Snapshot the VM now. The CKS questions that break the API server are much"
echo "less stressful when you can roll back."
