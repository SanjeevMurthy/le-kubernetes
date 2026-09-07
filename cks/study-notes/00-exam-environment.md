# CKS Study Notes — The Exam Environment

Everything here is fact, not technique. Knowing it removes the surprises that cost other candidates their first fifteen minutes. Verified against Linux Foundation pages on 6 September 2026; re-check the two pages linked at the bottom the week before you book.

<!-- toc -->
## Table of Contents

- [Exam facts at a glance](#exam-facts-at-a-glance)
- [The desktop](#the-desktop)
  - [Keys that are different here](#keys-that-are-different-here)
- [Hosts and tools](#hosts-and-tools)
- [Allowed documentation](#allowed-documentation)
- [Page titles worth memorising](#page-titles-worth-memorising)
- [The first two minutes on a task host](#the-first-two-minutes-on-a-task-host)
- [Habits the environment rewards](#habits-the-environment-rewards)
- [Before you book](#before-you-book)
- [Memorise](#memorise)

<!-- toc stop -->

## Exam facts at a glance

| | |
|---|---|
| Environment | Kubernetes **v1.35**. The published curriculum document is v1.34; the two numbers are different things and both are current. |
| Format | 15 to 20 performance-based tasks. Candidates consistently report 16. |
| Duration | 2 hours |
| Pass mark | **67 percent**, so about 11 of 16 tasks solved cleanly. Partial credit exists, so attempt every task. |
| Prerequisite | A passed CKA. It does not need to still be active. |
| Retake | One free retake per purchase, to be taken within 12 months of the original purchase date |
| Results | Emailed within 24 hours. No per-question feedback is ever given. |
| Validity | 2 years |
| Bonus | Passing or recertifying CKS on or after 18 June 2026 automatically extends the CKA under the CARE policy |
| Simulator | Two killer.sh sessions included with the voucher, **17 questions each and the two sets are different**, 36 hours of access from activation |

The arithmetic that matters: at 16 tasks and a 67 percent pass mark, you can leave three tasks untouched and still pass, but only if the other 13 are right. Speed on the tasks you know beats depth on the one you do not.

## The desktop

The exam is delivered through PSI Bridge in the PSI Secure Browser, and inside it you get a remote Linux desktop.

- **One monitor only.** Dual monitors are not supported. A 15 inch or larger screen at 1080p is recommended.
- No other applications or browser windows may be running.
- A terminal emulator, a Firefox restricted to the allowed documentation, and **VSCodium** with an integrated terminal you may use instead. Installing VSCodium extensions is disabled.
- A notepad inside the exam browser tab is the only place you may take notes.
- The task panel sits on the left and can be resized. Tasks can be **flagged** and reappear on a review screen.
- Timer alerts fire at 30, 15 and 5 minutes remaining. Breaks do not stop the timer.

### Keys that are different here

| Action | Key |
|---|---|
| Copy and paste inside the terminal | `Ctrl+Shift+C` and `Ctrl+Shift+V` |
| Copy and paste in Firefox and other apps | `Ctrl+C` and `Ctrl+V` |
| Close a window | `Ctrl+Alt+W`, because `Ctrl+W` is intercepted |
| Locate the mouse cursor | `Ctrl+Alt+K` |
| Enter insert mode in vim | Press `i`. **The INSERT key is disabled** in the remote desktop. |

An on-screen virtual keyboard is available if a physical key fails.

## Hosts and tools

This is the part that catches CKA holders out. There is no single cluster you stay on.

- You start on a base host whose hostname is `base`. **Never reboot it.** Rebooting the base system does not restart the exam environment.
- Every task names its own host in an infobox. Reach it with `ssh <nodename>`.
- **Nested SSH is not supported.** Finish the task, `exit` back to `base`, then ssh to the next host.
- `sudo -i` gives you root on any host.

Pre-installed and pre-configured on every SSH host:

| Tool | Note |
|---|---|
| `kubectl` | with the `k` alias and bash autocompletion already set up |
| `yq` | for YAML and JSON processing |
| `curl` and `wget` | for testing services and endpoints |
| `man` and the man pages | the only offline reference |

**There is no `jq`.** Older guides tell you to install it; do not plan around it. Use `kubectl -o jsonpath` or `yq -p json` instead. The base host has none of the tools above, because every task is meant to be done on a designated host.

Security tooling (Falco, Trivy, kube-bench, AppArmor utilities, `runsc`) is present on the node a task targets when that task needs it. Do not assume the Docker CLI is available; use `crictl` for container inspection and `podman` for image builds.

One official note worth reading twice: installing services and applications during the exam may require modifying system security policies. In other words, an AppArmor profile or a SELinux setting may be standing between you and a working service.

## Allowed documentation

This is a closed-book exam with eight exceptions. The full list, verbatim from the resources-allowed page:

| Source | URL |
|---|---|
| Kubernetes documentation | `https://kubernetes.io/docs/` |
| Kubernetes blog | `https://kubernetes.io/blog/` |
| Falco | `https://falco.org/docs/` |
| bom CLI reference | `https://kubernetes-sigs.github.io/bom/cli-reference/` |
| etcd | `https://etcd.io/docs/` |
| NGINX Ingress Controller user guide | `https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/` |
| Cilium | `https://docs.cilium.io/en/stable` |
| Istio | `https://istio.io/latest/docs/` |

Plus the task-specific links in each task's Quick Reference box, and documents installed by the distribution under `/usr/share`.

**Not allowed, and this is the trap:** Trivy, kube-bench, AppArmor and kubesec documentation, and GitHub. Searching kubernetes.io is allowed, but opening an external search result is not. Personal bookmarks are gone; the remote Firefox provides its own Documentation Quick Links.

The consequence for study: every flag of `trivy`, `kube-bench`, `kubesec`, `apparmor_parser` and `etcdctl` has to come from memory, from `--help`, or from `man`. That is why those tools dominate the `## Memorise` sections of the other notes.

## Page titles worth memorising

You cannot bookmark, so you navigate by searching kubernetes.io for a known title. These are the ones that pay off:

- Auditing
- Encrypting Confidential Data at Rest
- Restrict a Container's Access to Resources with AppArmor
- Restrict a Container's Syscalls with seccomp
- Enforce Pod Security Standards with Namespace Labels
- Network Policies
- Using RBAC Authorization
- Admission Controllers Reference, which contains the ImagePolicyWebhook configuration
- Runtime Class
- Certificate Signing Requests
- Upgrading kubeadm clusters

On falco.org: Supported Fields, and the rules reference. On docs.cilium.io: Network Policy, and Transparent Encryption.

`kubectl explain` is often faster than any of them. `kubectl explain pod.spec.securityContext --recursive` answers most field-name questions without leaving the terminal.

## The first two minutes on a task host

```bash
ssh <nodename>                 # the host named in the task infobox
sudo -i                        # root, needed for anything under /etc/kubernetes
hostname                       # confirm you are where you think you are
k config current-context       # the task usually gives you a context line: run it

# only if the task edits a static pod manifest:
cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.bak

# optional, one line, worth it for YAML-heavy tasks:
printf 'set nu sw=2 et ts=2 ai\n' >> ~/.vimrc
```

Do not build an elaborate alias set. Each task is a different host, so per-shell aliases do not persist, and `k` with completion is already there. Two candidates who passed in 2025 specifically advise not bothering with custom aliases at all.

## Habits the environment rewards

- **Scan every task first.** Note which are cheap and which are the known time sinks, then do the cheap ones. There are no visible per-task weights, so an easy task is worth as much as a hard one of the same size.
- **Run the context line the task gives you**, every time, before anything else.
- **Flag at 10 minutes.** The review screen exists for exactly this.
- **Keep the last 15 minutes to verify**, not to start something new.
- **Back up before you edit** anything under `/etc/kubernetes/manifests`. Recovering a dead API server without a backup is where candidates lose whole questions.
- **Return to `base`** after each task, so the next `ssh` starts from the right place.

## Before you book

Two pages change without notice. Re-read them the week before you book, and again the week before you sit:

- `https://docs.linuxfoundation.org/tc-docs/certification/important-instructions-cks` for the Kubernetes version and the environment rules
- `https://docs.linuxfoundation.org/tc-docs/certification/certification-resources-allowed` for the allowed documentation list

## Memorise

- Kubernetes **v1.35** environment, curriculum document v1.34, 16 tasks, 2 hours, **67 percent**.
- Eight allowed sources: kubernetes.io docs and blog, falco.org, bom, etcd.io, ingress-nginx, Cilium, Istio. Nothing else, and no GitHub.
- Tools present: `k` with completion, `yq`, `curl`, `wget`, `man`. **No `jq`.**
- `ssh <nodename>` from `base`, `sudo -i` for root, no nested SSH, never reboot `base`.
- `Ctrl+Shift+C` and `Ctrl+Shift+V` in the terminal, `Ctrl+Alt+W` not `Ctrl+W`, press `i` because INSERT is disabled.
- Back up `kube-apiserver.yaml` before editing it.
- Flag at 10 minutes, verify in the last 15.
