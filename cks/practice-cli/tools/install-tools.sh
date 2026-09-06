#!/usr/bin/env bash
# Install CKS practice tools on an Ubuntu or Debian kubeadm node.
# Usage: sudo bash tools/install-tools.sh [all | trivy kube-bench falco gvisor kubesec bom apparmor strace etcdctl ...]
set -o pipefail
[[ $EUID -eq 0 ]] || { echo "run as root (sudo -i)"; exit 1; }
ARCH=$(dpkg --print-architecture)
export DEBIAN_FRONTEND=noninteractive
apt_install() { apt-get install -y -q "$@" >/dev/null; }
need() { command -v "$1" >/dev/null 2>&1; }
gh_latest() { curl -s "https://api.github.com/repos/$1/releases/latest" | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/.*"\(v\{0,1\}[0-9][^"]*\)"/\1/'; }

i_trivy() {
  need trivy && return 0
  apt_install wget apt-transport-https gnupg
  wget -qO- https://get.trivy.dev/deb/public.key | gpg --dearmor -o /usr/share/keyrings/trivy.gpg
  echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://get.trivy.dev/deb generic main" > /etc/apt/sources.list.d/trivy.list
  apt-get update -q >/dev/null && apt_install trivy
}
i_kube_bench() {
  need kube-bench && return 0
  local v; v=$(gh_latest aquasecurity/kube-bench)
  curl -sL "https://github.com/aquasecurity/kube-bench/releases/download/${v}/kube-bench_${v#v}_linux_${ARCH}.deb" -o /tmp/kube-bench.deb && dpkg -i /tmp/kube-bench.deb >/dev/null
}
i_falco() {
  need falco && return 0
  curl -fsSL https://falco.org/repo/falcosecurity-packages.asc | gpg --dearmor -o /usr/share/keyrings/falco-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/falco-archive-keyring.gpg] https://download.falco.org/packages/deb stable main" > /etc/apt/sources.list.d/falcosecurity.list
  apt-get update -q >/dev/null && FALCO_FRONTEND=noninteractive apt_install falco
  systemctl enable --now falco-modern-bpf 2>/dev/null || systemctl enable --now falco
}
i_gvisor() {
  need runsc && return 0
  apt_install curl gnupg
  curl -fsSL https://gvisor.dev/archive.key | gpg --dearmor -o /usr/share/keyrings/gvisor-archive-keyring.gpg
  echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/gvisor-archive-keyring.gpg] https://storage.googleapis.com/gvisor/releases release main" > /etc/apt/sources.list.d/gvisor.list
  apt-get update -q >/dev/null && apt_install runsc
  if ! grep -q 'runtimes.runsc' /etc/containerd/config.toml 2>/dev/null; then
    cat >> /etc/containerd/config.toml <<'EOF'
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
  runtime_type = "io.containerd.runsc.v1"
EOF
    systemctl restart containerd
  fi
}
i_kubesec()  { need kubesec && return 0; curl -sL "https://github.com/controlplaneio/kubesec/releases/latest/download/kubesec_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin kubesec; }
i_bom()      { need bom && return 0; curl -sL "https://github.com/kubernetes-sigs/bom/releases/latest/download/bom-${ARCH}-linux" -o /usr/local/bin/bom && chmod +x /usr/local/bin/bom; }
i_apparmor() { need apparmor_parser && need aa-status && return 0; apt_install apparmor apparmor-utils; }
i_strace()   { need strace && return 0; apt_install strace; }
i_etcdctl()  { need etcdctl && return 0; apt_install etcd-client; }

tools=("$@")
if [[ ${#tools[@]} -eq 0 || "${tools[0]}" == all ]]; then tools=(trivy kube-bench falco gvisor kubesec bom apparmor strace etcdctl); fi
apt-get update -q >/dev/null 2>&1 || true
rc=0
for t in "${tools[@]}"; do
  fn="i_$(echo "$t" | tr '-' '_')"
  printf '%-12s' "$t"
  if declare -F "$fn" >/dev/null && "$fn"; then echo "ok"; else echo "FAILED (check the download URL or apt repo for $t)"; rc=1; fi
done
exit $rc
