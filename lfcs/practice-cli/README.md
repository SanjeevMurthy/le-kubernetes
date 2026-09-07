# LFCS Practice CLI

Forty-five exam-style tasks with automated setup, grading and cleanup, plus three scored mock exams. It runs as root inside a lab virtual machine and grades what you actually changed on the system.

<!-- toc -->
## Table of Contents

- [Requirements](#requirements)
- [The safety guard](#the-safety-guard)
- [Quick start](#quick-start)
- [Menu](#menu)
- [How a question is built](#how-a-question-is-built)
  - [Needs tags](#needs-tags)
  - [A second host without a second VM](#a-second-host-without-a-second-vm)
  - [Storage without spare disks](#storage-without-spare-disks)
  - [Verification philosophy](#verification-philosophy)
- [Generated files](#generated-files)
- [State](#state)
- [Never on a real host](#never-on-a-real-host)

<!-- toc stop -->

## Requirements

- **A lab virtual machine you can break.** Ubuntu 24.04 primary, Rocky 9 for the RHEL-family questions. Build both from [`../lab-setup/README.md`](../lab-setup/README.md), which also creates the marker file the CLI insists on.
- **Root.** Every question edits users, disks, firewall rules, systemd units or network configuration. `--env`, `--mock` and the interactive menu re-exec themselves under `sudo`; `--list` and `--help` do not.
- **Bash.** Menus stay bash 3.2 compatible so `--list` works on macOS. Question scripts run on Linux and assume bash 4.
- No extra tool installation. The provisioning scripts install everything the questions need, which is why there is no installer here.

## The safety guard

The CLI refuses to start on any host without `/etc/lfcs-lab`, written by the provisioning scripts. Override with `LFCS_ALLOW_HOST=1` only if you fully understand what you are about to do.

This is not a formality. The questions repartition disks, rewrite `/etc/fstab`, create and delete user accounts, replace firewall rulesets and change the default boot target. On a machine you care about, one of them will ruin your day.

Take a VM snapshot before each session. Recovering a machine that will not boot because of a bad `/etc/fstab` line is itself on the syllabus, so the lab is built to let that happen.

## Quick start

```bash
cd lfcs/practice-cli
./lfcs --list          # every question, no root needed
sudo ./lfcs --env      # what this host can actually run
sudo ./lfcs            # interactive
sudo ./lfcs --mock 1   # 120 minutes, scored
```

## Menu

| Key | Action |
|---|---|
| `1` | List every question with its domain, difficulty, needs tags and completion mark |
| `2` | Select a question |
| `3` | Random incomplete question |
| `4` | Progress, overall and per domain |
| `5` | Mock exam, 120 minutes, scored |
| `E` | Environment check |
| `Q` | Quit |

Inside a question: `S` sets the scenario up, `Q` shows the task, `H` shows the solution, `V` verifies your work, `C` cleans up, `B` goes back.

## How a question is built

Each question is a self-contained folder under `questions/`:

| File | Purpose |
|---|---|
| `meta` | Bash-sourceable: `id`, `title`, `domain`, `domain_short`, `difficulty`, `needs`, `weight`, `minutes`, `sources`, `host` |
| `question.md` | The task, in exam wording, with exact names and paths |
| `solution.md` | Steps, why they work, how to verify, and the man pages to reach for |
| `setup.sh` | Creates the real starting state and prints the scenario facts |
| `verify.sh` | PASS and FAIL checks; exits non-zero on any failure |
| `cleanup.sh` | Removes what setup created and restores every file it backed up |

### Needs tags

`meta`'s `needs` field says what a question requires. `sudo ./lfcs --env` matches the tags against the current host and reports what can run here.

| Tag | Meaning |
|---|---|
| `disk` | A spare block device, or a free loop device to back a file with |
| `netns` | The kernel can create network namespaces, used to make a peer host |
| `host2` | The other lab VM is reachable over SSH as `node2` |
| `nic2` | At least two real network interfaces |
| `ubuntu`, `rocky` | Pinned to one distribution |
| `virt` | `virsh` present and `libvirtd` running |
| `tool:<name>` | That command is on PATH |

### A second host without a second VM

Questions about NFS, routing, packet filtering and network block devices need traffic from somewhere else. Rather than requiring both VMs to be running, `make_netns_peer` builds a peer inside a network namespace, with a veth pair and optionally an http, ssh or NFS service. The verifier then tests from outside the host, which is the only honest way to grade a firewall.

Only the questions tagged `host2` want the second VM genuinely reachable over SSH.

### Storage without spare disks

Storage questions prefer a real spare disk, because it behaves in `lsblk` exactly as the exam's does. `spare_disk` returns one only when it has no filesystem, no mount point and no partitions, and a cross-question claim file stops two questions taking the same device. When no such disk exists, `make_loop_disk` backs a file with a loop device instead, so the whole set runs on a single-disk VM.

### Verification philosophy

Verifiers test effect, not file text. A firewall question opens connections from the peer namespace. A quota question writes as the constrained user until the write fails. A service question connects to the port.

Two rules matter more here than anywhere else:

- **Persistence is graded separately from live effect.** The exam scores a change that does not survive a reboot as zero, so every question checks the running system and then the file that would rebuild it at the next boot. `scripts/check-persistence.py` refuses to let a question skip this without a written reason.
- **A negative test carries a control.** A command can fail for the wrong reason, and a failure for the wrong reason looks exactly like the failure being graded. Where a question grades a refusal, it first proves the mechanism is live.

## Generated files

Never edit these by hand. Each generator refuses to write when its inputs look wrong.

```bash
bash tools/build-registry.sh   # questions/*/meta      -> lib/questions.sh
bash tools/build-guide.sh      # questions/*/          -> lfcs-exam-qa-guide.md
bash tools/build-mock.sh N     # ../mock-exams/mock-N.set -> mock-N.md
```

From the repository root, `bash scripts/regenerate.sh lfcs` runs all of them plus the lab table and the tables of contents, and `bash scripts/check-docs.sh` fails if any checked-in copy has drifted.

## State

Progress, timers and mock results live in `/var/lib/lfcs`, outside the repository, so a `git clean` never erases your record and the repository never carries your answers.

## Never on a real host

Read this once more before you run it anywhere unfamiliar. This CLI is a deliberate wrecking ball: it exists to put a machine into a broken state so you can practise fixing it. Run it only inside a lab VM you are willing to roll back to a snapshot.
