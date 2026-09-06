# CKS Real Exam Questions: What Candidates Report Seeing

This file is the evidence layer of the CKS kit. It records the task types that candidates report
meeting on the exam, with a source count for each, so that every frequency claim made anywhere else
in the repo can be traced back to a named write-up rather than to opinion.

The inventory below was compiled on 6 September 2026 from 28 candidate write-ups published between
September 2021 and August 2026, most of them first-hand exam reports, plus the published question
and scenario catalogues that mirror the exam: the killer.sh simulator question list mirrored at
`snigdhasambitak/cks` (22 questions), the 42 free Killercoda Killer-Shell scenarios, the ViktorUJ
open simulator (22 labs), UnixArena's 15 "questions and answers", kyle-heller's 55 scripted
questions, Ron Amosa's mock notes, Jinal Desai's 26-post series and the sailor.sh topic guide.

A task type is counted once per distinct source. A count of 12 therefore means twelve different
write-ups, question sets or scenario catalogues describe that kind of task. It does not mean the
task is worth 12 percent of the exam, and it does not mean twelve candidates met it on the same
day. The Linux Foundation does not publish per-task weights and states that it "does not report
performance on individual items", so no per-task percentage exists to quote.

These are task *types* reconstructed from candidate memory. Nothing here is a verbatim exam
question, and nothing here was copied from a live exam. The Linux Foundation certification
agreement forbids sharing actual exam content, and every candidate cited below wrote up their
experience under that constraint, which is why their phrasings differ from each other and why the
"Phrasing" column paraphrases except where the research quotes a candidate directly.

The shape of the exam sets the stakes for every count below. The Linux Foundation states that the
CKS is two hours long and "consist[s] of 15-20 performance-based tasks", and that a score of 67
percent or above is needed to pass. First-hand reports converge tighter than the official range:
Aditya Joshi, cuffaro and the Spectro Cloud guide all say 16 questions, and gentx2 describes
running out of time on "4 questions out of 16". The killer.sh simulator, which ships with the exam
purchase, uses 17 questions per session. Plan for 16 or 17 tasks, of which about 11 must be right.

Each task also runs on a designated host reached with `ssh <nodename>`, with a return to the host
named `base` afterwards, so a task type's "starting state" below often describes files on a node
rather than objects in the API. That is why so many of these task types are file edits rather than
kubectl commands, and why a task that looks small can cost ten minutes of ssh, backup and restart.

Two version numbers matter and are easy to confuse. The exam environment runs Kubernetes v1.35.
The published curriculum document is `CKS_Curriculum v1.34.pdf`, released on 30 October 2025. The
domain weights below come from that curriculum document. Nothing in the inventory depends on the
difference between the two versions.

## Frequency tiers

Tier 1 is a task family reported by 10 or more independent sources. Tier 2 is 6 to 9 sources.
Tier 3 is fewer than 6. The tiers exist to set a study order, not to predict a specific exam form.

**Tier 1: reported by 10 or more sources.** These appear in every simulator and in most first-hand
reports. Expect to meet nearly all of them.

| Task family | Sources |
|---|---|
| Falco: find the offending pod, write or modify a rule, produce a log in a required format | 15 |
| Audit logging: write the policy, wire the `--audit-*` flags and the hostPath volumes | 13 |
| ImagePolicyWebhook admission | 12 |
| kube-bench and CIS remediation | 12 |
| AppArmor: load the profile on the node, enforce it on a pod | 12 |
| NetworkPolicy: default deny, selectors, DNS egress, metadata block | 12 |
| RBAC least privilege | 10 |
| gVisor RuntimeClass | 10 |

**Tier 2: reported by 6 to 9 sources.** Common enough that skipping any one of them is a gamble.

| Task family | Sources |
|---|---|
| API server flags: anonymous auth, NodePort exposure, authorization mode, NodeRestriction, etcd TLS | 9 |
| Trivy image scanning | 9 |
| Dockerfile and manifest static analysis | 8 |
| Secrets: encryption at rest, reading a secret from etcd | 8 |
| Cilium: CiliumNetworkPolicy L3 to L7, transparent encryption | 8 |
| Binary verification with sha512sum | 7 |
| Ingress with a TLS secret | 7 |
| Pod Security Admission via namespace labels | 6 |
| Container immutability | 6 |
| kubeadm cluster upgrade | 6 |
| ServiceAccount hygiene | 6 |

**Tier 3: reported by fewer than 6 sources.** Worth one pass each, not worth a rehearsal loop.

| Task family | Sources |
|---|---|
| strace and syscall investigation | 5 |
| OPA Gatekeeper constraint and template edits | 5 |
| SBOM with bom, plus kubesec and KubeLinter | 5 |
| Kubelet hardening in `/var/lib/kubelet/config.yaml` | 5 |
| Linux host hardening: users, groups, services, ports, packages | 4 |
| kubeconfig contexts and certificate extraction | 4 |
| Node metadata endpoint protection | 4 |
| CSR and user certificates | 3 |
| Istio mTLS with PeerAuthentication STRICT | 3 |
| Kubernetes Dashboard hardening | 2 |
| Cosign and image signing | 1 |

The practical consequence: the CKS exam is 15 to 20 performance-based tasks, and candidates
consistently report 16 or 17. Eight tier-1 families plus eleven tier-2 families cover nineteen
distinct kinds of work, so a 16-task exam draws roughly 10 to 12 of its tasks from tiers 1 and 2.
Passing needs 67 percent, which is about 11 solid tasks out of 16. Rehearsing tiers 1 and 2 until
they are automatic is therefore the whole game, and tier 3 is what to read once and leave alone.

Three things the tiers do not tell you. First, a tier is not a probability: no source knows the
exam form, and a single sitting can miss a tier-1 family entirely. Second, a tier is not a
difficulty rating; RBAC sits in tier 1 and is among the fastest tasks on the exam, while the
kubeadm upgrade sits in tier 2 and is one of the slowest. Third, a tier is not a time budget, since
several tier-1 families are multi-step: Trung Tran reports that "each question normally has 2-3
tasks, and each task requires 2-3 different steps". Use the tiers to decide what to drill, and use
the gotcha column of each table to decide how long to allow for it on the day.

A note on the low counts. A count of 1 or 2 usually means the topic is new or retired rather than
rare. Istio was added to the curriculum bullet in April 2025, so most write-ups predate it. Cosign
has no first-hand report at all. The Dashboard bullet was deleted in October 2024, so its two
sources are both historical. Age of the source matters as much as the count.

## Domain 1 — Cluster Setup (15%)

Five curriculum bullets sit here: network security policies, CIS benchmark review of etcd, kubelet,
kubedns and kubeapi, Ingress with TLS, node metadata protection, and binary verification. Six of
the seven task types below are node-level or control-plane-level work, so most of them start with
`ssh <nodename>` and `sudo -i` rather than with kubectl.

| # | Task type | Sources | Phrasing as candidates remember it | Starting state | Gotchas | Drill |
|---|---|---|---|---|---|---|
| 1 | NetworkPolicy: default deny, namespace and pod selectors, DNS egress | 12 | "Create a new default-deny NetworkPolicy named defaultdeny in the namespace production for all traffic of type Ingress"; "Create a NetworkPolicy named pod-restriction to restrict access to Pod products-service" (UnixArena) | Namespaces and pods already labelled; sometimes an existing wrong policy to correct | Selectors are OR at list level and AND inside one list item; allow UDP and TCP 53 when denying egress; `podSelector: {}` selects the whole namespace; the exam CNI (Cilium or Calico) really enforces the policy | Q1 |
| 2 | Node metadata endpoint protection | 4 | Egress NetworkPolicy blocking 169.254.169.254, or a lab address such as 192.168.100.21 | A pod that can currently reach the metadata endpoint | `ipBlock.except` is the mechanism; the `/32` matters; check the cloud metadata address the task names rather than assuming 169.254.169.254 | Q24 (planned) |
| 3 | kube-bench and CIS remediation | 12 | "Fix CIS findings such as disabling anonymous access on the API server/kubelet, secure authorization mode" (Muqees); "ensure authorization-mode includes Node and RBAC" (UnixArena); "set tls version and allowed ciphers for etcd, kube-api" (ViktorUJ 23) | kube-bench installed; several FAIL items seeded across apiserver, kubelet and etcd | Know the CIS-id to file mapping (1.x apiserver, 1.2.x etcd, 4.2.x kubelet); kubelet fixes need `systemctl restart kubelet`; the apiserver-to-etcd TLS item was reported as covered by neither KodeKloud nor Killercoda (hemjal1) | Q2, Q22 (planned) |
| 4 | Kubelet hardening in `/var/lib/kubelet/config.yaml` | 5 | Usually arrives inside a kube-bench task as the 4.2.x findings | kubelet with `authentication.anonymous.enabled: true`, a `readOnlyPort`, or AlwaysAllow authorization | Edit the config file, not the systemd unit, on a kubeadm cluster; restart kubelet after every edit; Ron Amosa's mock notes name "fix failures in /var/lib/kubelet/config.yaml" as its own step | Q2, Q22 (planned) |
| 5 | Ingress with a TLS secret | 7 | "Create/update ingress with TLS support and enforce SSL redirection" (Muqees) | ingress-nginx installed; certificate and key files given; often an existing HTTP-only Ingress | `kubectl create secret tls` takes `--cert` and `--key`; `spec.tls[].hosts` must match the rule host and `secretName` the new secret; add `nginx.ingress.kubernetes.io/ssl-redirect: "true"`; prove it with `curl -kv` against the HTTPS URL | Q3 |
| 6 | Binary verification with sha512sum | 7 | "Compare SHA512 hashes of Kubernetes binaries in /opt/binaries against provided values and delete mismatched files" (Namrata D) | Several binaries plus a file of expected hashes | `sha512sum <file>` compared against the given value, or `sha512sum --check` on a hash file; hash the running kubelet binary too, not only the staged download; read whether the task wants the bad file deleted or only reported | Killercoda "Verify Platform Binaries" |
| 7 | Kubernetes Dashboard hardening | 2 | Change the Dashboard service type and container args | Dashboard installed with an insecure service or skip-login enabled | The GUI bullet was removed from the curriculum in October 2024, so this row is historical; it survives only in the killer.sh mirror (Q8) and one 2022 guide | none (retired) |

**Where the time goes.** The NetworkPolicy and Ingress tasks are the quick wins of this domain and
should be banked early. kube-bench is the slow one, because the loop is run the tool, read the FAIL
id, map the id to a file, edit, restart the component and re-run. Muqees reports the task being
scoped to a single check, as in `kube-bench run --targets=node --check 4.1.1`, which is far faster
than reading a full report, so look for the check number in the task text before scrolling output.

**How to prove it.** Every task in this domain has a cheap end-state test. For a policy, run a
throwaway pod and try the connection that should fail and the DNS lookup that must still succeed.
For Ingress, `curl -kv` the HTTPS URL and look at both the certificate and the redirect. For a CIS
fix, re-run the same targeted kube-bench check and confirm it turned into a PASS. For a binary,
re-run `sha512sum` after the change. A hardening edit that silently broke DNS or the kubelet scores
zero, so the verification step is not optional politeness, it is where the marks are.

## Domain 2 — Cluster Hardening (15%)

Every task in this domain is an access-control task, and graders check the effective permission
rather than the YAML that produced it. Three of the six touch
`/etc/kubernetes/manifests/kube-apiserver.yaml`, the file most often named in failure reports. The
standing advice from Valiev, Trung Tran, Giorgi and Lakhera is identical: copy that manifest to
`/root` before the first edit.

| # | Task type | Sources | Phrasing as candidates remember it | Starting state | Gotchas | Drill |
|---|---|---|---|---|---|---|
| 8 | RBAC least privilege: roles, bindings, `auth can-i` | 10 | "Edit existing Role for service-account-web to allow only get operations on Pods; create role-2 for StatefulSet updates" (UnixArena) | An over-permissive Role or ClusterRole already bound to a ServiceAccount or user | Build them imperatively with `kubectl create role` and `kubectl create rolebinding`; a ServiceAccount subject is `system:serviceaccount:<ns>:<name>`; verify with `kubectl auth can-i --as`; delete `system:anonymous` bindings when the task says so | Q4, Q29 (planned) |
| 9 | ServiceAccount hygiene: automount, unused accounts, token projection | 6 | "Create a new ServiceAccount named backend-sa in the existing namespace prod; clean up unused accounts" (UnixArena); disable mounting on the default ServiceAccount | Pods running as the default ServiceAccount with a token mounted | `automountServiceAccountToken: false` on the ServiceAccount applies to its pods, on the pod it overrides the ServiceAccount; verify inside the pod that `/var/run/secrets/kubernetes.io/serviceaccount` is gone; a token secret is no longer created automatically | Q5 |
| 10 | API server flags: anonymous auth, NodePort exposure, authorization mode, NodeRestriction, etcd TLS | 9 | "Change the apiserver setup so that it is only accessible through a ClusterIP Service", meaning remove `--kubernetes-service-node-port` (Namrata D); "Reconfigure API server with authorization-mode=Node,RBAC; delete system:anonymous ClusterRoleBinding" (UnixArena) | An insecure flag seeded in `/etc/kubernetes/manifests/kube-apiserver.yaml` | Every save restarts the apiserver, so watch `crictl ps` or `watch kubectl get pod -n kube-system` after each edit; recover from `/var/log/pods/kube-system_kube-apiserver-*/`; a broken apiserver that stays broken loses the marks for the whole question | Q6, Q23 (planned), Q33 (planned), Q37 (planned) |
| 11 | kubeconfig contexts and certificate extraction | 4 | "Extract all kubectl context names to /opt/contexts and decode user certificates from kubeconfig" | A multi-cluster kubeconfig | `kubectl config get-contexts -o name` gives the bare list the task usually wants; `kubectl config view --raw -o jsonpath` then `base64 -d` for the client certificate; there is no `jq` on the exam hosts | Killercoda kubeconfig scenario |
| 12 | CSR and user certificates | 3 | Create the CSR, approve it, extract the certificate, build a kubeconfig for the new user | Key and CSR files provided on the node | `signerName: kubernetes.io/kube-apiserver-client` for a user cert; the request field is base64 of the PEM CSR with no newlines; `kubectl certificate approve` then read `.status.certificate`; the new user still needs a RoleBinding | Q40 (planned) |
| 13 | kubeadm cluster upgrade | 6 | "Update Kubernetes cluster", control plane first and then the worker | Cluster one minor version behind | Valiev lists the upgrade among the most time-consuming tasks, so flag it and return; drain with `--delete-emptydir-data --ignore-daemonsets`; upgrade kubeadm, then run `kubeadm upgrade`, then kubelet and kubectl, then `systemctl daemon-reload && systemctl restart kubelet`; uncordon at the end | Q39 (planned) |

**Where the time goes.** RBAC and ServiceAccount work is fast and should be done early. The kubeadm
upgrade is the slowest single task reported anywhere in the research and is the classic candidate
for the flag button. The apiserver tasks are fast to edit and slow to recover, which is the trap:
the kubelet rescans `/etc/kubernetes/manifests` roughly every 20 seconds, so after a save the right
move is to wait and watch rather than to edit again and stack a second mistake on the first.

**How to prove it.** Permissions are checked by impersonation, with `kubectl auth can-i` plus
`--as system:serviceaccount:<ns>:<name>`, which asks the question the grader is asking. For
apiserver changes, confirm the static pod came back with `crictl ps` and only then re-run kubectl.
If kubectl hangs, the recovery path reported by KodeKloud and by several candidates is
`systemctl restart kubelet`, then the kubelet journal filtered for apiserver messages, then
`crictl ps -a` and `crictl logs`, and finally the newest directory under `/var/log/pods` matching
the apiserver. Rehearse that sequence before the exam, because the reported cost of failing to
recover an apiserver is the marks for the entire question.

## Domain 3 — System Hardening (10%)

The smallest domain, and the one that sank the most recent first-hand fail report: suzuki0430
scored 44 percent on the first attempt and named Linux administration as the weakness, then passed
with 79 percent four days later. The curriculum bullet names AppArmor and seccomp together, and the
kit drills seccomp as Q8 and Q30 alongside the AppArmor row below.

| # | Task type | Sources | Phrasing as candidates remember it | Starting state | Gotchas | Drill |
|---|---|---|---|---|---|---|
| 14 | AppArmor: load a profile on the node, enforce it on a pod | 12 | "Enforce prepared AppArmor profile at /etc/apparmor.d/nginx_apparmor; apply to Pod manifest" (UnixArena); killer.sh puts the profile at `/opt/course/9/profile` and wants the logs at `/opt/course/9/logs` | The profile file is present on a worker node but not loaded; the pod uses the deprecated annotation or nothing | The profile *name* inside the file is not the filename (Lakhera); load with `apparmor_parser -q <file>` and confirm with `aa-status`; since Kubernetes 1.30 use `securityContext.appArmorProfile` with `type: Localhost`, the annotation is still accepted; the pod must be scheduled on the node holding the profile; `kubectl replace --force` after editing a running pod | Q7, Q34 (planned) |
| 15 | Linux host hardening: users, groups, services, open ports, packages, SSH | 4 | "Linux users and groups" (kaizendae); suzuki0430 remembers `gpasswd`, `chgrp` and `systemctl` work | A rogue service, package, user or listening port on a node | `ss -tlpn` to find the port and its process, `systemctl disable --now` to stop it surviving reboot, `apt remove` for the package, `usermod -L` and `gpasswd -d` for the account; do only what is asked, since the graders check the named condition and nothing else | Q41 (planned), Q42 (planned) |

**Where the time goes.** Both task types here run on a named worker node, not on the control plane,
so the first minute is ssh and `sudo -i`. The reported time sink is not the edit but the missing
restart: Walter Lee and Ron Amosa both list failure to restart the kubelet after a kubelet-config
or AppArmor change as a mistake that leaves a correct-looking file scoring nothing. Seccomp belongs
to the same curriculum bullet as AppArmor, with node profiles living under
`/var/lib/kubelet/seccomp/profiles/` and the pod referencing one through
`securityContext.seccompProfile` with `type: Localhost`. The kit drills seccomp as Q8 and
Q30 (planned) beside the AppArmor row above.

**How to prove it.** `aa-status` shows whether the profile is loaded and in which mode. `ss -tlpn`
shows whether the port is really closed and by which process. `systemctl status` shows whether the
service will stay dead across a reboot rather than merely being stopped now. For a pod under a
profile, run the action the profile is meant to block and confirm it is denied, since a profile in
complain mode looks identical to one in enforce mode until something tries to break the rule.

## Domain 4 — Minimize Microservice Vulnerabilities (20%)

One of the three 20 percent domains. Its six task types split into pod-level policy (Pod Security
Admission, Gatekeeper), secrets, and isolation (gVisor, Cilium, Istio). Two candidates who failed a
first attempt named this domain: Parasxidis retook the exam because he "did not adequately master
or expect the depth of Falco and Cilium questions", and Arslan lists Cilium L3 to L7 as required
knowledge.

| # | Task type | Sources | Phrasing as candidates remember it | Starting state | Gotchas | Drill |
|---|---|---|---|---|---|---|
| 16 | Pod Security Admission and Standards via namespace labels | 6 | "apply `pod-security.kubernetes.io/enforce: baseline` label; find which pods violate and write to /opt/course/4/logs" (killer.sh) | A namespace with no PSA labels and some non-compliant pods already running | `enforce` blocks only new pods, so existing violators keep running and the "write the violations to a file" step comes from the warn or audit output; `restricted` needs `runAsNonRoot`, seccomp `RuntimeDefault` and all capabilities dropped; read PSS rejection messages as hints (Valiev) | Q9, Q36 (planned) |
| 17 | Secrets: encryption at rest, reading a secret from etcd, decode and mount | 8 | "Read the complete Secret content directly from ETCD" (ViktorUJ 11); "Encrypt secrets in ETCD" and then re-encrypt the existing ones | An apiserver with no `--encryption-provider-config`; etcd certificates in `/etc/kubernetes/pki/etcd/` | `ETCDCTL_API=3 etcdctl` needs `--cacert`, `--cert` and `--key` from `/etc/kubernetes/pki/etcd/`; the first provider in the list is the one used for writes, so `identity` first means no encryption; existing secrets stay in plaintext until they are rewritten; verify the `k8s:enc:aescbc` prefix in etcd; the config file needs its own hostPath mount in the static pod | Q10, Q25 (planned), Q26 (planned) |
| 18 | gVisor RuntimeClass | 10 | "Create a RuntimeClass named gvisor using the prepared runtime handler named runsc" (UnixArena); "Pod gvisor-test … write dmesg output to /opt/course/10/gvisor-test-dmesg" (Jinal Desai, mirroring killer.sh) | containerd already configured with the runsc handler on one node | `handler: runsc` in lowercase; the pod needs both `runtimeClassName` and node targeting, because only one node has the handler; prove it with `kubectl exec … -- dmesg` showing the gVisor banner; `runsc --version` on the node confirms the runtime is really installed | Q12, Q28 (planned) |
| 19 | Cilium: CiliumNetworkPolicy L3 to L7, transparent encryption | 8 | "Install Cilium with WireGuard"; "Cilium network policy with mTLS" (ViktorUJ); L7 HTTP rules (Arslan) | Cilium is already the CNI; a policy skeleton is provided | Only `docs.cilium.io` is on the allowed list and the online policy editor is not; a CiliumNetworkPolicy is a CRD, so `kubectl explain` still works but the field names differ from NetworkPolicy; verify encryption with `cilium encrypt status` inside the cilium DaemonSet pod; a KodeKloud lab grader expected a Helm install and rejected `cilium install --encryption wireguard` | Q35 (planned) |
| 20 | Istio mTLS with PeerAuthentication STRICT | 3 | No first-hand phrasing beyond "Istio" appeared in any write-up | Istio pre-installed in the cluster | Istio joined the curriculum bullet in April 2025, which is why the count is low rather than because the topic is easy; only `istio.io` docs are allowed; `PeerAuthentication` in the workload namespace with `mtls.mode: STRICT`, and the mesh-wide version lives in the Istio root namespace | Q44 (planned) |
| 21 | OPA Gatekeeper constraint and template edits | 5 | "modify OPA/Gatekeeper constraints to blacklist image registries and test" | Gatekeeper installed with a ConstraintTemplate and Constraint already applied | Only `kubectl edit` of the CRDs is needed and Gatekeeper is never installed by the candidate; read the rego rather than writing it (cuffaro); test the change by creating a pod that must be rejected; 2026 guides now also teach ValidatingAdmissionPolicy for the same job | Q11 |

**Where the time goes.** The secrets task is the expensive one, because reading a secret straight
out of etcd means typing three certificate paths correctly before anything happens, and encrypting
at rest means editing the apiserver static pod again. Cilium is the other cost, and it is the one
candidates most often say they underestimated. gVisor, Pod Security Admission and a Gatekeeper
constraint edit are all short tasks once the syntax is memorised.

**How to prove it.** Each isolation task has a physical proof rather than a YAML inspection.
For gVisor, `dmesg` inside the pod shows the sandbox. For encryption at rest, an `etcdctl get` on
the secret key shows the `k8s:enc:aescbc` prefix instead of readable text. For Cilium encryption,
`cilium encrypt status` inside the DaemonSet pod reports the state. For Pod Security Admission and
for Gatekeeper, create the pod that must be rejected and read the rejection message, which Valiev
recommends treating as a hint rather than an error, because it names the exact field that failed.

## Domain 5 — Supply Chain Security (20%)

The curriculum bullets are base image footprint, understanding the supply chain, securing it with
permitted registries and signing, and static analysis with Kubesec and KubeLinter. Note the tool
asymmetry: bom documentation is on the allowed list, but Trivy, kubesec and KubeLinter
documentation is not, so those command lines have to come from memory or from `--help`.

| # | Task type | Sources | Phrasing as candidates remember it | Starting state | Gotchas | Drill |
|---|---|---|---|---|---|---|
| 22 | Dockerfile and manifest static analysis, "find the two issues" | 8 | "Analyze and edit the given Dockerfile (ubuntu:16.04) … fixing two instructions … and the given manifest … fixing two fields", with the instruction to "only modify existing configuration settings, not add or remove" (UnixArena and killer.sh phrasing) | Files under `/opt/course/<n>/files` | The recurring answers are `USER root` changed to a non-root user, a `:latest` or end-of-life base image, `privileged: true`, `allowPrivilegeEscalation: true`, hard-coded credentials and `hostNetwork`; fix exactly the number of issues the task names and do not improve anything else; killer.sh also asks for the filenames with credential exposure written to a file | Q15, Q27 (planned) |
| 23 | SBOM with bom, plus kubesec and KubeLinter | 5 | `bom generate --image nginx:… -o sbom.json`; `kubesec scan pod.yaml` | Manifest or image files provided on the node | bom is the one tool here whose docs are allowed, at kubernetes-sigs.github.io/bom; kubesec output is a JSON list with a `score` and `advise` block, and the task usually wants the score or the top advice; no `jq` exists on the hosts, so read the output with `yq` or by eye | Q15, Q38 (planned) |
| 24 | ImagePolicyWebhook admission | 12 | "Enable image policy plugin; configure implicit deny (`defaultAllow: false`); point to HTTPS scanner endpoint" (UnixArena); "enable an ImagePolicyWebhook solution that's already created, with an existing webhook-backend Service" | An AdmissionConfiguration file and a kubeconfig skeleton pre-created in `/etc/kubernetes/admission-controllers/` or `/etc/kubernetes/epconfig/`; the backend Service already exists | Three files plus apiserver flags plus a hostPath mount, which is why this is the most reported way to kill the API server; Valiev failed his first attempt by forgetting the `server:` field in the webhook kubeconfig; Walter Lee misspelled the plugin name; it needs `--admission-control-config-file` and `ImagePolicyWebhook` in `--enable-admission-plugins`; test with a pod that must be denied | Q14, Q21 (planned) |
| 25 | Trivy: scan the images used in a namespace, delete or report the vulnerable pods | 9 | "Detect and delete Pods using images with High/Critical vulnerabilities in kamino namespace" (UnixArena); "remember to use --severity=CRITICAL" (jayendrapatil) | A namespace with four to six pods, one or two of them on vulnerable images | List the images first with `-o custom-columns`; `trivy image --severity HIGH,CRITICAL <image>`; scans are slow, so start them in a second terminal and work elsewhere while they run; read carefully whether the task wants the pod deleted, the deployment deleted, or only the image name written to a file | Q13 |
| 26 | Cosign and image signing | 1 | No first-hand phrasing exists; the curriculum bullet says "sign and validate artifacts" | Not reported | Only the sailor.sh guide mentions it and no candidate report does, so learn `cosign verify` and digest pinning once and spend the time elsewhere | Killercoda "Image Use Digest" |

**Where the time goes.** ImagePolicyWebhook dominates this domain: three files, two apiserver
flags and a volume mount, on the file that breaks clusters. Trivy is second, not because it is hard
but because the scans themselves are slow, which is why several candidates start a scan in one
terminal and keep working in another. The static analysis task is quick if the instruction is
followed literally and slow if it turns into a general clean-up of the manifest.

**How to prove it.** For an admission task, the proof is a pod that must be rejected: create it,
read the rejection, then create one that must be allowed. For a scanning task, the proof is the
deliverable, and this is where marks leak. jayendrapatil warns to read the information marked with
the `i` icon, and a KodeKloud thread records a candidate scanning the image when the task wanted
the whole namespace. Before leaving any task in this domain, re-read the sentence that says where
the answer goes, because "delete the pod", "delete the deployment" and "write the image name to
/opt/course/N/..." are three different answers to what looks like one question.

## Domain 6 — Monitoring, Logging and Runtime Security (20%)

The two heaviest task types on the whole exam live here. Falco at 15 sources and audit logging at
13 are the most reported task types in the research, and both are multi-step: Falco usually means
find the pod, fix the rule, format the output and act on the finding, while audit logging means a
policy file plus five flags plus two volume entries in the static pod. A KodeKloud forum reply
names cluster hardening and runtime security as "the most time-consuming" pairing.

| # | Task type | Sources | Phrasing as candidates remember it | Starting state | Gotchas | Drill |
|---|---|---|---|---|---|---|
| 27 | Falco: find the offending pod, write or modify a rule, produce a log in a required format | 15 | "Identify pods running nginx with unwanted package management processes / httpd modifying /etc/passwd; save logs in format `time,container-id,container-name,user-name`" (Namrata D); "Investigate Falco logs … gather Pod name and namespace using crictl" (Tuladhar); "scale offending Deployments to zero" (UnixArena) | Falco installed as a systemd service on a worker node; rules in `/etc/falco/falco_rules.yaml`, overrides in `/etc/falco/falco_rules.local.yaml`; file output sometimes disabled | The output fields are `%evt.time`, `%container.id`, `%container.name` and `%user.name`, and `falco --list` is the in-exam reference since only falco.org docs are allowed; an override must reuse the same rule name; reload with `systemctl restart falco`; file output is off by default (Lakhera); `crictl` maps the container id back to a pod; one candidate hit Falco stream failures under exam load | Q16, Q19 (planned), Q31 (planned) |
| 28 | Audit logging: write the policy, wire the `--audit-*` flags and the hostPath volumes | 13 | "Enable audit logs at /var/log/kubernetes/audit-logs.txt with 30-day retention and max 10 backup files" (UnixArena); a policy with `RequestResponse` for named resources, `Metadata` for secrets and `None` elsewhere; killer.sh adds "investigate a break-in via the audit log" | A partial policy file at `/etc/kubernetes/audit/policy.yaml`; the apiserver has no audit flags yet | Both `volumes` and `volumeMounts` must be added, which is the step suzuki0430 missed; use `FileOrCreate` for the log file and `DirectoryOrCreate` for the policy directory, and the log mount must not be read-only (Ron Amosa); the flags are `--audit-policy-file`, `--audit-log-path`, `--audit-log-maxage=30`, `--audit-log-maxbackup=10`, `--audit-log-maxsize=100`; any policy syntax error kills the apiserver on save | Q17, Q20 (planned), Q32 (planned) |
| 29 | strace and syscall activity investigation | 5 | "identify processes using forbidden kill syscall" (killer.sh); "process tracing via strace and crictl" (kubegeek) | A pod running on a worker node, with `strace` available on the node | `crictl ps` then `crictl inspect` to get the PID, then `strace -p <pid>`; one failed candidate could not authenticate to crictl at all, so run `sudo -i` first and confirm crictl works before spending time on the trace; the answer is usually a syscall name or a process name written to a file | Q43 (planned) |
| 30 | Container immutability: readOnlyRootFilesystem, no privileged, emptyDir for writable paths | 6 | "Inspect and delete Pods in development namespace that store data or use privileged configurations" (UnixArena); killer.sh calls it "Immutable Root FileSystem" | A deployment whose container writes to `/tmp` or `/var/cache/nginx` | `readOnlyRootFilesystem: true` alone crash-loops nginx, so add `emptyDir` mounts for every path it writes; `privileged: true` disqualifies a pod on its own; the securityContext fields are container-level here, not pod-level, which is the distinction suzuki0430 flags as worth memorising | Q18 |

**Where the time goes.** These are the two most reported task types on the exam and both are
multi-step, so this domain deserves the largest share of preparation time. A KodeKloud forum reply
names cluster hardening and runtime security as the most time-consuming pairing, singling out CIS
benchmarks, audit logs and Falco configuration. Falco was also the topic Arnav Tripathy skipped in
preparation and then met on his failed first attempt, and it is one of the two topics Parasxidis
blames for his retake. Nothing in the research supports leaving either of them until the day.

**How to prove it.** Falco alerts land in the journal for the falco unit, and in
`/var/log/falco.log` only when file output has been switched on, which it is not by default. After
any rule edit, restart the service and trigger the behaviour the rule watches for, then confirm the
alert appears in the exact field order the task asked for. For audit logging, tail the log path
named in the task and confirm entries appear at the requested level, remembering that the apiserver
has to come back healthy first. For immutability, the proof is that the pod runs rather than
crash-loops after the root filesystem is made read-only.

## What is no longer on the exam

**The Kubernetes Dashboard.** The Cluster Setup bullet "Minimize use of, and access to, GUI
elements" existed in the v1.29 curriculum and was removed in the rewrite that went live on 15
October 2024. The domain also grew from 10 percent to 15 percent in the same change, and the
Ingress bullet changed from "security control" to "TLS". Task type 7 above still carries 2 sources
because the killer.sh mirror and a 2022 guide describe a Dashboard task, but both predate the
rewrite. Giorgi Keratishvili, who sat the exam four days after the change, confirms the shift.

**PodSecurityPolicy.** PSP was removed from Kubernetes itself and the October 2024 curriculum
replaced the old pod-security wording with "Use appropriate pod security standards". Pod Security
Admission with the `pod-security.kubernetes.io/enforce`, `/audit` and `/warn` namespace labels is
what the exam tests now, and it is task type 16 above. The RX-M summary of the update lists PSP
removal alongside the Cilium, SBOM and Kubesec additions.

**What the same rewrite changed rather than removed.** Two domain weights moved on 15 October 2024:
Cluster Setup rose from 10 percent to 15 percent and System Hardening fell from 15 percent to 10
percent. "Update Kubernetes frequently" became "Upgrade Kubernetes to avoid vulnerabilities",
"Minimize IAM roles" became "Using least-privilege identity and access management", and the supply
chain bullets picked up SBOM, artifact repositories, Kubesec and KubeLinter by name. Cilium arrived
as the named pod-to-pod encryption tool, with Istio added to the same bullet in April 2025. A
pre-2024 study plan therefore misallocates study time even where it names the right topics.

Both topics still appear in older material. Namrata D's 2023 tips series covers PSP, several
community repositories still list Dashboard tasks, and older allowed-documentation lists still show
Trivy and AppArmor documentation as permitted when the current list does not. Read anything written
before October 2024 with that in mind, and prefer the curriculum document plus post-2024 reports.

## Sources

Twenty-eight candidate write-ups, newest first. Outcomes are as stated by the author, and where an
entry is a preparation guide rather than an exam report that is said plainly, because a guide is
still a source for what task types exist but is weaker evidence for what appeared on a given day.
Eight of the twenty-eight report failing a first attempt, and every one of them passed a later
attempt, usually within days and usually with a large jump in score, which is worth knowing when
reading the gotcha columns above: most of them were written by someone who had just lost marks to
exactly that gotcha.

Nothing in this file is attributed to Reddit. During the research on 6 September 2026 every Reddit
route failed: the reader proxy returned HTTP 403 "blocked due to a network policy", the search API
returned HTML instead of JSON, and the pullpush.io archive rate-limited the query. Two Medium posts
could not be read in full, numbers 1 and 5 below, so only their preview text and search snippets
were usable, and neither contributes a task-type count on its own.

1. Prateek Jain, Medium on a custom domain, 2026-08-19. Pass, 75 percent. Body paywalled, preview only.
   https://blog.prateekjain.dev/cks-exam-experience-2026-preparation-strategy-and-lessons-learned-1fad785a430b
2. suzuki0430, dev.to, 2026-04-09. Fail 44 percent on 2026-03-13, then pass 79 percent on 2026-03-17.
   https://dev.to/suzuki0430/from-failure-to-success-cks-exam-report-and-tips-for-future-kubestronauts-4ipk
3. Gurban Valiev, Medium, 2026-01-31. Fail 55 percent on 2026-01-21, then pass 90 percent on 2026-01-24.
   https://medium.com/@gurbanvaliev1/cks-2026-my-path-to-the-kubernetes-security-certification-fe70d49cbc5c
4. Abdul Muqees, Medium, 2026-01-02. Practical guide series, no personal result stated.
   https://medium.com/@abdul.muqees194/cks-practical-guide-part-2-domain-specific-security-scenarios-cluster-setup-602e41b0cb67
5. Malek Zaag, Medium, November 2025. Pass, 89 percent, Kubestronaut. Article returned 404 through every route; only the search snippet was readable.
   https://medium.com/@malek.zaag/i-just-cleared-the-new-2025-cks-exam-heres-the-blueprint-you-can-follow-to-pass-too-84e81fb1ec37
6. KodeKloud forum, "Preparing for the CKS Exam", 2025-10-28. Study plan thread, no result stated.
   https://kodekloud.com/community/t/preparing-for-the-cks-exam-sharing-my-study-plan-and-challenges/488852
7. Alonso Parasxidis Moreno, Medium, 2025-10-07. Retake needed, then pass; Golden Kubestronaut.
   https://medium.com/@alonso.parasxidis/from-zero-to-golden-kubestronaut-my-journey-through-the-cncf-certification-landscape-7dca2de22674
8. Aman Pathak, Stackademic and YouTube, 2025-09-26. Pass.
   https://blog.stackademic.com/everything-you-need-to-know-for-the-cks-exam-topics-resources-and-tips-237b752d6f22
9. Kienlt, Medium, 2025-08-20. Preparation guide, result not stated.
   https://medium.com/@kienlt.qn/prepare-for-the-certified-kubernetes-security-specialist-cks-exam-in-2025-b8bdcac60e4b
10. Muhammad Fahad, dev.to, 2025-07-30. Guide, result not stated.
   https://dev.to/muhammadfahad/how-to-easily-pass-the-cks-exam-real-tips-from-a-dev-45f0
11. Ron Amosa, uncommonengineer.com, notes updated 2025-07-04. Practice-exam notes from two killer.sh and three KodeKloud mocks.
   https://www.uncommonengineer.com/docs/study/CKS/ExamNotes/
12. kaizendae, personal blog, 2025-04-13. Pass, 83 percent, on 2025-04-12 after 40 days of preparation.
   https://www.kaizendae.com/blog/CKS
13. Toon Van Deuren, Medium, 2025-03-25. 57 percent, then 66 percent one point short, then pass 90 percent.
   https://medium.com/@toonvandeuren/certified-kubernetes-security-specialist-cks-a-quick-debrief-b06132fbfff4
14. Arslan Ali, Medium, 2025-01-31. Fail then pass; Kubestronaut in 40 days.
   https://arslanwrites.medium.com/achieving-kubestronaut-in-40-at-40-4ca86245d9f4
15. Mauricio Quevedo, Medium, 2025-01-24. 44 percent, then 64 percent, then pass.
   https://medium.com/@mauricioqdevops/the-ultimate-cks-guide-2025-28918e5245ea
16. KodeKloud forum, "CKS exam experience", hemjal1 2024-08-25, gentx2 2024-10-03, kubegeek 2024-12-13. gentx2 passed with four of sixteen questions unanswered; kubegeek failed.
   https://kodekloud.com/community/t/cks-exam-experience/463973
17. Giorgi Keratishvili, LinkedIn, 2024-10-19. Pass, on the updated "CKS 2.0" exam.
   https://www.linkedin.com/pulse/how-ace-cks-20-certified-kubernetes-security-exam-giorgi-keratishvili-gw2sf
18. Arnav Tripathy, Medium, 2024-05-19. Fail 49 on 2024-05-12, then pass 74 on 2024-05-18.
   https://arnavtripathy98.medium.com/my-cks-experience-c56a5cf9ff6f
19. Prasad, LinkedIn, 2024-01-07. Pre-exam cheat sheet; the author passed per the article title.
   https://www.linkedin.com/pulse/cks-one-last-blog-post-refer-before-you-step-exam-prasad-fyvkc
20. Namrata D, Medium, 2023-07-14. Tips series with worked examples, no result stated.
   https://namrata23.medium.com/how-to-pass-the-cks-exam-tips-and-tricks-with-examples-part-i-5e481481d603
21. Aditya Joshi, LinkedIn, 2023-05-09. Pass, prepared in two weeks; reports 16 questions.
   https://www.linkedin.com/pulse/how-i-passed-cks-2-weeks-aditya-joshi
22. Trung Tran, LinkedIn, 2023-01-30, updated 2024-04-11. Pass after roughly four weeks of course work and mocks.
   https://www.linkedin.com/pulse/how-pass-certified-kubernetes-security-specialist-exam-trung-tran
23. Glen Yu, Medium, 2022-12-20. Pass.
   https://medium.com/@glen.yu/my-thoughts-on-the-certified-kubernetes-security-specialist-cks-exam-68ff38a30878
24. Rajat Umrao, KodeKloud forum, 2022-11-17. Pass, with notes on a slow exam environment at 2 AM.
   https://kodekloud.com/community/t/cleared-my-cks-exam-recently-adding-some-points-based-on-my-experience-as-e/227265
25. cuffaro.com, 2022-03-20. Pass, 81 out of 100, after about six weeks; reports roughly 16 scenarios.
   https://cuffaro.com/2022-03-20-cks-experience/
26. Walter Lee, LinkedIn, 2022-02-01. Pass without finishing every task.
   https://www.linkedin.com/pulse/cks-exam-tips-tldr-walter-lee
27. Spectro Cloud, Zulfi Ahamed, 2022-01-17. Guide; reports 16 questions and a ten-tool list.
   https://www.spectrocloud.com/blog/certified-kubernetes-specialist-cks-cracker-tips-and-tricks
28. Prashant Lakhera, Medium, 2021-09-22. Pass, write-up deliberately limited by the NDA.
   https://devopslearning.medium.com/my-road-to-certified-kubernetes-security-specialist-cks-d26a8e9b50bc

Beyond these 28 write-ups, the source counts also draw on published question and scenario
catalogues, each counted once: the killer.sh question list mirrored at
https://github.com/snigdhasambitak/cks, the Killer-Shell Killercoda scenarios at
https://killercoda.com/killer-shell-cks, the ViktorUJ open simulator labs at
https://github.com/ViktorUJ/cks, UnixArena's fifteen questions and answers at
https://unixarena.com/2024/10/how-to-pass-the-cks-exam-questions-and-answers-you-need-to-know.html/,
kyle-heller's scripted question set at https://github.com/kyle-heller/CKS-PREP-2025, Jinal Desai's
question series at https://jinaldesai.com/cks-certification-q10/ and the sailor.sh topic guide at
https://sailor.sh/blog/cks-exam-topics/.

## How to use this file

This file sets the priority order for the practice-CLI question bank: build and rehearse the tier-1
and tier-2 drills first, because they are where 10 to 12 of a 16-task exam comes from, and treat
tier 3 as a single read-through. It is also the origin of every "n sources" number quoted in the
study notes under [`../../study-notes/`](../../study-notes/), so a count that appears in a recipe
should match the row here, and a count that does not match is a bug in the recipe rather than a new
fact. Re-check the whole file if the curriculum changes: the current document is v1.34 published on
30 October 2025 and the exam environment is Kubernetes v1.35, and a new curriculum version would
invalidate the domain weights, possibly the task inventory, and certainly the retired-topics list.
