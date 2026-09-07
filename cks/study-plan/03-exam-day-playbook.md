# CKS Exam Day Playbook

Read this the evening before and skim it the morning of. Nothing here is new material. It is the set of habits that turn what you know into marks, drawn from 28 first-hand candidate write-ups.

Exam: **Saturday 12 December 2026**.

<!-- toc -->
## Table of Contents

- [The night before](#the-night-before)
- [Thirty minutes before](#thirty-minutes-before)
- [The first three minutes of the exam](#the-first-three-minutes-of-the-exam)
- [The first two minutes of each task](#the-first-two-minutes-of-each-task)
- [While you work](#while-you-work)
- [Verify every task before you leave it](#verify-every-task-before-you-leave-it)
- [When the API server does not come back](#when-the-api-server-does-not-come-back)
- [The mistakes that cost other people the exam](#the-mistakes-that-cost-other-people-the-exam)
- [The last fifteen minutes](#the-last-fifteen-minutes)
- [Afterwards](#afterwards)

<!-- toc stop -->

## The night before

- [ ] Run the PSI system check on the exact machine you will use. Not a similar one.
- [ ] Confirm the room will be quiet, private, well lit, and that the desk is clear.
- [ ] One monitor. Dual monitors are not supported and will stop the exam.
- [ ] Charge and plug in. Use a wired network connection if you have one.
- [ ] No new material. Re-read [`../cheatsheets/cks-exam-cheatsheet.md`](../cheatsheets/cks-exam-cheatsheet.md) and stop.
- [ ] Sleep. Every debrief that mentions fatigue mentions it as a cause of lost time.

## Thirty minutes before

- [ ] Join early. Check-in, ID and the room scan take real time, and the clock does not start until you are admitted, so there is no cost to being early and a real cost to being late.
- [ ] Close every other application and browser window.
- [ ] Water within reach. Breaks do not stop the timer.

## The first three minutes of the exam

1. Read the ReadMe tab.
2. **Skim every task.** Note two things per task: how confident you are, and which host it runs on. This is the single highest-return three minutes of the exam, because it turns an unknown queue into a plan.
3. Decide your order: confident and short first, known time sinks last. There are no visible per-task weights, so a five-minute task earns as much as a twenty-minute one of the same size.

The known time sinks, from candidate reports: the kubeadm cluster upgrade, ImagePolicyWebhook, and the audit policy. All three are worth doing, but not first.

## The first two minutes of each task

```bash
ssh <nodename>                 # exactly the host named in the task infobox
sudo -i                        # root, needed for anything under /etc/kubernetes
hostname                       # confirm you are where you think you are
k config current-context       # run the context line the task gives you
```

If the task edits a static pod manifest, back it up before anything else:

```bash
cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.bak
```

Do not build an alias set. Each task is a different host, `k` with completion is already configured, and two candidates who passed in 2025 advise skipping custom aliases entirely. One line is worth it for YAML-heavy tasks:

```bash
printf 'set nu sw=2 et ts=2 ai\n' >> ~/.vimrc
```

## While you work

- **Read the whole task before typing.** Several debriefs describe losing marks by solving a slightly different problem, or by deleting a pod when the task asked for the image name in a file.
- **Note the deliverable.** If it says write something to `/opt/course/<n>/<file>`, that file is the mark.
- **Flag at 10 minutes.** The review screen exists for this. A flagged task you return to is worth more than a finished task you rushed into breaking something.
- **Use two terminals.** One holds the editor, the other runs `watch crictl ps` or `kubectl get pod -n kube-system` while a control-plane component restarts.
- **`exit` back to base** before the next task. Nested SSH is not supported.
- **Never reboot the base host.** It does not restart the environment.
- **Never block ports 8080, 4505 or 4506.** Firewall tasks that close them will end your session.

## Verify every task before you leave it

Sixty seconds per task. This is where the difference between 65 and 75 percent lives.

| Task family | The command that proves it |
|---|---|
| RBAC | `k auth can-i <verb> <resource> --as=system:serviceaccount:<ns>:<sa> -n <ns>` including a case that must say no |
| NetworkPolicy | `k run probe --rm -it --image=busybox:1.36 -- wget -T3 -qO- <target>` and an `nslookup` to prove DNS still works |
| Pod Security Admission | `k run bad --image=nginx --privileged -n <ns>` must be rejected |
| AppArmor | `aa-status \| grep <profile>` then `k exec <pod> -- touch /tmp/x` must fail |
| seccomp | the pod is Running, and the blocked syscall actually fails inside it |
| gVisor | `k exec <pod> -- dmesg \| head` shows gVisor |
| Encryption at rest | `etcdctl get /registry/secrets/<ns>/<name>` shows `k8s:enc:aescbc:v1:` |
| Audit | `tail /var/log/kubernetes/audit/audit.log` grows after a `kubectl get secrets -A` |
| Falco | the alert appears in `journalctl -u falco-modern-bpf -u falco` in the required format |
| Ingress TLS | `curl -kv --resolve <host>:443:<ip> https://<host>` |
| Immutability | `k exec <pod> -- touch /x` fails while the pod stays Running |
| API server edit | `curl -k https://127.0.0.1:6443/readyz` returns ok |

## When the API server does not come back

This is the most expensive failure in the exam, and it is recoverable if you stay calm. The kubelet rescans `/etc/kubernetes/manifests` about every 20 seconds, so **wait before you re-edit**. Re-editing repeatedly is what turns a two-minute recovery into a lost question.

```bash
# 1. Is it even trying?
crictl ps -a | grep apiserver

# 2. Why did it stop?
crictl logs <container-id> 2>&1 | tail -30

# 3. If the container never started, the manifest itself is bad
journalctl -u kubelet --since '-3 min' | grep -iE 'apiserver|manifest|yaml'

# 4. If the container started and died, its logs are on disk
ls -t /var/log/pods/kube-system_kube-apiserver-*/kube-apiserver/ | head -1

# 5. Last resort: restore and re-apply the change more carefully
cp /root/kube-apiserver.yaml.bak /etc/kubernetes/manifests/kube-apiserver.yaml
```

The four causes candidates actually hit: a misspelled flag, a `volumeMounts` entry with no matching `volumes` entry, YAML indentation, and a webhook kubeconfig missing its `server:` line.

## The mistakes that cost other people the exam

1. **Spending the first hour on three questions.** Flag and move.
2. **Working on the wrong host.** The infobox names it. Check `hostname` after every `ssh`.
3. **Not restarting the kubelet** after changing `/var/lib/kubelet/config.yaml` or loading an AppArmor profile.
4. **Deleting the wrong resource.** There is no undo. `k get <res> -o yaml > /root/backup.yaml` before any delete.
5. **Skipping Falco in preparation.** It is the most reported task family on the exam.
6. **Assuming `jq` exists.** It does not. Use `yq` or `-o jsonpath`.
7. **Trying to open documentation that is not allowed.** Trivy, kube-bench, AppArmor and kubesec docs are blocked; know those flags cold.
8. **Not verifying.** A task that looks right and is not scores zero, and sixty seconds would have caught it.

## The last fifteen minutes

Stop starting new work. Instead:

1. Return to every flagged task and get partial credit where you can. Partial credit counts.
2. Re-run the verification command for every task you completed early, because a later task may have changed cluster state.
3. Confirm every deliverable file exists and has content.
4. Confirm no task was left on the wrong host.

## Afterwards

Results arrive by email within 24 hours, with no per-question breakdown. If it did not pass, reschedule the free retake immediately while the environment is fresh in your memory. Of the 28 write-ups behind this kit, eight failed on the first attempt and every one of them passed the retake, usually with a large jump: 55 to 90, 44 to 79, 49 to 74.

Passing also extends your CKA under the CARE policy, which protects the Kubestronaut track while LFCS is in progress.
