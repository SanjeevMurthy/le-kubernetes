# CKS Lab Setup

Two tiers. Tier 1 runs on this Mac and covers every question that only needs `kubectl`. Tier 2 is a browser playground that gives a real kubeadm cluster with a root shell, which is the only way to practise the node-level half of the exam.

Build both before the first study weekend (26 September 2026).

<!-- toc -->
## Table of Contents

- [Disk space first](#disk-space-first)
- [Tier 1: minikube with Calico](#tier-1-minikube-with-calico)
  - [The context guard](#the-context-guard)
- [Tier 2: Killercoda](#tier-2-killercoda)
- [KodeKloud labs](#kodekloud-labs)
- [Which questions run where](#which-questions-run-where)
- [Optional: a kubeadm cluster you own](#optional-a-kubeadm-cluster-you-own)
- [Safety](#safety)

<!-- toc stop -->

## Disk space first

The Mac has roughly 26 GB free and minikube with Calico wants about 8 GB. Reclaim space before starting.

```bash
df -h /System/Volumes/Data                 # check free space
open -a Docker                             # Docker Desktop must be running for the minikube docker driver
docker system df                           # what Docker is holding
docker system prune -a --volumes           # reclaim unused images, containers and volumes
minikube delete -p cka-multinode           # the old CKA cluster, if it is no longer needed
minikube delete -p minikube
brew cleanup
```

Target at least 15 GB free before creating the cluster.

## Tier 1: minikube with Calico

Calico matters. The default minikube CNI does not enforce NetworkPolicy, so a policy question would pass verification while traffic still flowed. Every NetworkPolicy question in this kit assumes an enforcing CNI.

```bash
minikube start -p cks \
  --driver=docker \
  --nodes=2 \
  --cpus=2 --memory=3g \
  --cni=calico \
  --kubernetes-version=v1.35.0

kubectl config use-context cks
kubectl get nodes -o wide
kubectl -n kube-system rollout status ds/calico-node --timeout=300s
```

If `v1.35.0` is rejected, list what is available with `minikube config defaults kubernetes-version` and take the newest 1.35 patch. The exam environment tracks v1.35; nothing in the CKS curriculum depends on the patch level.

Add the pieces some questions need:

```bash
# Ingress controller (Q3 Ingress TLS)
minikube addons enable ingress -p cks

# Kyverno (Q11 admission policy, Q14 registry restriction)
kubectl create -f https://github.com/kyverno/kyverno/releases/latest/download/install.yaml
kubectl -n kyverno rollout status deploy/kyverno-admission-controller --timeout=300s
```

Stop the cluster between sessions rather than deleting it:

```bash
minikube stop -p cks      # keeps the cluster, frees the RAM
minikube start -p cks     # back in about a minute
```

### The context guard

The practice CLI refuses to run against a context whose name contains `aks`, `eks`, `gke` or `prod`, and against any context not on its allow-list. This is deliberate: the CKS questions edit RBAC, admission control and node files, and the active context on this machine is a work AKS cluster. Always confirm before starting:

```bash
kubectl config current-context    # must print cks
```

## Tier 2: Killercoda

The free Killer Shell CKS playground gives a two-node kubeadm cluster with root, which minikube cannot provide. Every question tagged `node-root` needs it: AppArmor, seccomp, Falco, kube-bench, kubelet and API server flags, audit logging, encryption at rest, gVisor, the cluster upgrade and strace.

1. Open <https://killercoda.com/killer-shell-cks> and start the **Playground** scenario.
2. On the control plane:

```bash
git clone -b cks https://github.com/SanjeevMurthy/le-kubernetes
cd le-kubernetes/cks/practice-cli
sudo bash tools/install-tools.sh all      # Falco, Trivy, kube-bench, gVisor, kubesec, bom
./cks --env                                # confirm which questions are runnable
./cks
```

3. Sessions are one hour on the free tier. That is enough for four to six node-level questions if the tools are already installed, so run the installer first and keep the session open.

The 42 named Killer Shell scenarios are listed by domain in [`../study-plan/02-resources.md`](../study-plan/02-resources.md). They are the best free substitute for the exam environment because the desktop and the task structure match.

## KodeKloud labs

The KodeKloud CKS course provides in-browser clusters with root, so it covers the same node-level ground as Killercoda. Use it for the guided first pass through a topic and Killercoda for unguided repetition. The course lab clusters have historically lagged the exam Kubernetes version by a release or two, which does not matter for any CKS task.

## Which questions run where

`./cks --env` prints the authoritative answer for whatever host you are on, by matching each question's `needs` tags against the environment. In summary, **18 of the 44 questions run on minikube** and the rest need a root shell on a kubeadm node.

| # | Question | Domain | minikube | Killercoda | Also needs |
|---|---|---|---|---|---|
| Q1 | NetworkPolicy: Default-Deny + Selective Allow | D1 | yes | yes | Calico |
| Q2 | CIS Benchmark Remediation with kube-bench | D1 | no | yes | kube-bench |
| Q3 | Ingress TLS Termination | D1 | yes | yes | ingress-nginx |
| Q4 | RBAC Least-Privilege Role + Binding | D2 | yes | yes | — |
| Q5 | ServiceAccount Token Hardening | D2 | yes | yes | — |
| Q6 | Restrict the API Server (apiserver flags) | D2 | no | yes | — |
| Q7 | AppArmor Profile on a Pod | D3 | no | yes | apparmor_parser |
| Q8 | Seccomp RuntimeDefault + Custom Profile | D3 | no | yes | — |
| Q9 | Enforce Pod Security Admission (restricted) | D4 | yes | yes | — |
| Q10 | Encrypt Secrets at Rest (EncryptionConfiguration) | D4 | no | yes | etcdctl |
| Q11 | Admission Policy with Kyverno/Gatekeeper | D4 | yes | yes | Kyverno |
| Q12 | Runtime Sandbox with RuntimeClass (gVisor) | D4 | no | yes | runsc |
| Q13 | Scan Images with Trivy and Remediate | D5 | yes | yes | trivy |
| Q14 | Restrict Images via ImagePolicyWebhook/Registry | D5 | no | yes | — |
| Q15 | Static Analysis & Manifest Hardening (kubesec) | D5 | yes | yes | kubesec |
| Q16 | Detect Threats with Falco Rules | D6 | no | yes | falco |
| Q17 | API Server Audit Logging Policy | D6 | no | yes | — |
| Q18 | Immutable Containers (readOnlyRootFilesystem) | D6 | yes | yes | — |
| Q19 | Falco: change the output format and save the alerts | D6 | no | yes | falco |
| Q20 | Audit log forensics: who deleted the Secret | D6 | yes | yes | — |
| Q21 | ImagePolicyWebhook: complete the config and deny unverified images | D5 | no | yes | — |
| Q22 | kube-bench: fix the kubelet findings | D1 | no | yes | kube-bench |
| Q23 | The API server is down: find and fix the manifest | D2 | no | yes | — |
| Q24 | Block the cloud metadata endpoint | D1 | yes | yes | Calico |
| Q25 | Read a Secret straight from etcd | D4 | no | yes | etcdctl |
| Q26 | Encryption at rest: add a new key and re-encrypt | D4 | no | yes | etcdctl |
| Q27 | Fix two issues in the Dockerfile and two in the manifest | D5 | yes | yes | — |
| Q28 | Run a Pod under gVisor and capture dmesg | D4 | no | yes | runsc |
| Q29 | Remove anonymous access and scope the ServiceAccount | D2 | yes | yes | — |
| Q30 | seccomp: block mkdir with a Localhost profile | D3 | no | yes | — |
| Q31 | Falco: identify the offending pod and stop it | D6 | no | yes | falco |
| Q32 | Audit: ordered policy and retention flags | D6 | no | yes | — |
| Q33 | Restrict TLS versions and ciphers | D1 | no | yes | — |
| Q34 | AppArmor: the profile name is not the file name | D3 | no | yes | apparmor_parser |
| Q35 | CiliumNetworkPolicy: allow only GET /health | D4 | yes | playground | Cilium |
| Q36 | Pod Security: enforce baseline and report violators | D4 | yes | yes | — |
| Q37 | The API server is down again: a volume is wrong | D2 | no | yes | — |
| Q38 | Generate an SBOM and count its packages | D5 | yes | yes | bom |
| Q39 | Upgrade kubelet and kubectl on the worker to the latest patch | D2 | no | yes | — |
| Q40 | Issue a client certificate to user jane and bind a Role | D2 | yes | yes | openssl |
| Q41 | Host hardening: stop the rogue service and close its port | D3 | no | yes | — |
| Q42 | Host hardening: users, sudo and kernel modules | D3 | no | yes | — |
| Q43 | Which pod calls the kill syscall | D6 | no | yes | strace |
| Q44 | Istio: enforce STRICT mTLS in a namespace | D4 | yes | playground | Istio |

Two rows deserve a note. The Cilium and Istio questions need a cluster running that software, so use the Killercoda Cilium playground for the first and read the recipe for the second; there is no free Istio scenario. Everything marked `node-root` is what the Killercoda Killer Shell CKS playground exists for.

## Optional: a kubeadm cluster you own

Once the LFCS Ubuntu VM exists (December), it can double as an offline kubeadm cluster for node-level practice with no session timer:

```bash
sudo bash ../../lfcs/lab-setup/kubeadm-single-node.sh
```

Give the VM 6 GB of RAM first. This is a convenience, not a requirement; Killercoda covers the same ground.

## Safety

These scenarios edit API server manifests, kubelet configuration, audit policy, encryption keys, AppArmor profiles and node services. Run them only on a disposable practice cluster. Never on a cluster anyone else uses. Always run cleanup when a question is finished.
