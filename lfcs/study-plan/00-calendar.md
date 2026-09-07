# LFCS Calendar — 13 December 2026 to 6 February 2027

Eight weeks from the lab build to exam day, starting the day after the CKS exam.

**Legend:** 🎥 KodeKloud lesson · 📓 note in [`../study-notes/`](../study-notes/) · 🧪 practice CLI question · 📇 Anki · ⏱️ timed, target 6 minutes per task · 🐧 runs on `lfcs-ubuntu` · 🎩 runs on `lfcs-rocky`

**Pace.** 10 to 12 hours a week through January, easing in the final week. Weekdays carry 15 minutes of Anki; the substance is at weekends.

**The habit this exam rewards.** Every change must survive a reboot, and every task happens on a named host. Both are drilled from the first question: the verifiers check persistence separately from live effect, and the lab uses `ssh node1` and `ssh node2` rather than a local shell.

---

<!-- toc -->
## Table of Contents

- [Before Sunday 13 December](#before-sunday-13-december)
- [Week 1 — 13 to 20 Dec · Lab, then Essential Commands and Users](#week-1--13-to-20-dec--lab-then-essential-commands-and-users)
- [Week 2 — 21 to 27 Dec · Operations and Deployment (25%)](#week-2--21-to-27-dec--operations-and-deployment-25)
- [Week 3 — 28 Dec to 3 Jan · Storage (20%)](#week-3--28-dec-to-3-jan--storage-20)
- [Week 4 — 4 to 10 Jan · Networking (25%)](#week-4--4-to-10-jan--networking-25)
- [Week 5 — 11 to 17 Jan · Drills](#week-5--11-to-17-jan--drills)
- [Week 6 — 18 to 24 Jan · Drills and the first simulator](#week-6--18-to-24-jan--drills-and-the-first-simulator)
- [Week 7 — 25 to 31 Jan · Closing the gaps](#week-7--25-to-31-jan--closing-the-gaps)
- [Week 8 — 1 to 6 Feb · Exam week](#week-8--1-to-6-feb--exam-week)
- [After the exam](#after-the-exam)
- [If the date slips](#if-the-date-slips)

<!-- toc stop -->

## Before Sunday 13 December

- [ ] **Book the LFCS exam for Saturday 6 February 2027.** Not yet booked. Booking releases the two killer.sh sessions this calendar schedules on 23 January and 3 February.
- [ ] Voucher expiry is confirmed: **3 March 2027**. Sit the exam no later than **Saturday 13 February** whatever else slips, because that is the last date leaving two retake Saturdays.
- [ ] Free 50 GB on the Mac and download both installer images: [`../lab-setup/README.md`](../lab-setup/README.md).
- [ ] Enrol in the KodeKloud LFCS course.

## Week 1 — 13 to 20 Dec · Lab, then Essential Commands and Users

- [ ] **Sun 13 Dec: build the lab.** Both VMs, provisioned, snapshotted as `clean`, `ssh node1` and `ssh node2` working. Allow an afternoon.
- [ ] 📓 `00-exam-environment.md`, then `06-linux-basics-refresher.md`
- [ ] 📓 `04-essential-commands.md` and `05-users-and-groups.md`
- [ ] 🎥 KodeKloud: Essential Commands, then Users and Groups
- [ ] 🧪 🐧 Q32 to Q37 (git, find and permissions, text processing, archives and links, redirection, OpenSSL)
- [ ] 🧪 🐧 Q41 to Q44 (user lifecycle, sudo and password policy, ACLs, profiles and limits)
- [ ] 📇 Cards: `useradd` flags, `chage` flags, `setfacl` syntax, SUID and SGID and sticky, `find -perm`, `openssl x509` flags
- [ ] Close-out: create a user with an exact UID, shell, group, home and expiry from memory, then prove every attribute

## Week 2 — 21 to 27 Dec · Operations and Deployment (25%)

- [ ] 📓 `01-operations-deployment.md`, all eleven recipes
- [ ] 🎥 KodeKloud: Operations and Deployment
- [ ] 🧪 🐧 Q1 to Q8, Q10, Q11 (sysctl, processes, cron and at, timers, packages, boot targets, libvirt, podman, service units, journald)
- [ ] 🧪 🎩 Q9 SELinux: contexts, ports, booleans
- [ ] 📇 Cards: unit file sections, `OnCalendar` syntax, `systemctl` verbs, `semanage` and `restorecon`, `journalctl` filters
- [ ] Close-out: write a service unit and a timer from memory, enable both, and prove they survive a reboot

## Week 3 — 28 Dec to 3 Jan · Storage (20%)

- [ ] 📓 `03-storage.md`, all nine recipes
- [ ] 🎥 KodeKloud: Storage
- [ ] 🧪 🐧 Q23 to Q31 (partition and fstab by UUID, LVM create, LVM extend online, swap, quota, RAID 1, LUKS, NBD, disk-full triage)
- [ ] 📇 Cards: `pvcreate`, `vgcreate -s`, `lvextend -r`, `mkswap` and `swapon -p`, `mdadm --create`, `cryptsetup luksFormat`, `findmnt --verify`
- [ ] Close-out: grow a mounted logical volume and its filesystem without unmounting, then reboot the VM and confirm everything comes back

## Week 4 — 4 to 10 Jan · Networking (25%)

- [ ] 📓 `02-networking.md`, all eleven recipes
- [ ] 🎥 KodeKloud: Networking
- [ ] 🧪 🐧 Q12 to Q22 (static IP, routes, hostname and resolver, chrony, sshd, firewall, NAT and redirect, bridge, reverse proxy, NFS, troubleshooting)
- [ ] 🧪 🎩 The firewalld and nmcli variants of Q17 and Q12
- [ ] 📇 Cards: netplan versus nmcli, `nft` rule syntax and where each distribution persists it, `sshd -T`, `chronyc sources`, the three exam ports never to block
- [ ] **Sun 10 Jan: repo mock 1** as a baseline. Restore the `clean` snapshot first. Expect a low score; it is a measurement, not a verdict.

## Week 5 — 11 to 17 Jan · Drills

- [ ] ⏱️ Every question, interleaved and timed, 6 minute target
- [ ] Reboot drill: after each storage or networking question, reboot the VM and re-run the verifier. Anything that fails was never persistent.
- [ ] 🎥 KodeKloud mock exams 1 and 2
- [ ] **Sat 16 Jan: repo mock 2.** Target 70 percent or better.

## Week 6 — 18 to 24 Jan · Drills and the first simulator

- [ ] ⏱️ Weak areas from mock 2, plus every `rocky` question on the Rocky VM
- [ ] Two-host drills: Q21 NFS and Q30 NBD against `node2` rather than the namespace peer
- [ ] **Sat 23 Jan: killer.sh session 1.** The 36 hour clock starts on activation, so do not activate early.
- [ ] Sun 24 Jan: review every session 1 miss and turn each into a card and a drill

## Week 7 — 25 to 31 Jan · Closing the gaps

- [ ] ⏱️ Every question whose best time is still over 6 minutes
- [ ] 🎥 KodeKloud mock exams 3 and 4
- [ ] Re-score [`01-domain-checklists.md`](01-domain-checklists.md). Target: nearly every line `[x]`.
- [ ] **Sun 31 Jan: repo mock 3.** Target 85 percent or better.

## Week 8 — 1 to 6 Feb · Exam week

- [ ] Mon and Tue: Anki, plus one timed question a day from the weakest domain
- [ ] **Wed 3 Feb: killer.sh session 2.** Different questions from session 1.
- [ ] Thu: review session 2 misses only
- [ ] Fri: no new material. Re-read [`03-exam-day-playbook.md`](03-exam-day-playbook.md) and [`../cheatsheets/man-page-navigation.md`](../cheatsheets/man-page-navigation.md). Confirm the PSI system check passes.
- [ ] **Saturday 6 February: exam.** Join 30 minutes early. Quick tasks first, firewall and networking last, 6 minutes a task, verify persistence before leaving each one.

---

## After the exam

- [ ] Results arrive by email within 24 hours.
- [ ] If it did not pass, reschedule the free retake immediately. Three Saturdays remain before the 3 March expiry: 13, 20 and 27 February. Results arrive within 24 hours and there is no enforced wait, so booking the next Saturday is realistic.
- [ ] Passing completes the Golden Kubestronaut requirement that sits outside CNCF.

---

## If the date slips

| Situation | What to change |
|---|---|
| CKS moved into January | Do **not** shift LFCS with it. Compress the drill weeks instead. The LFCS deadline is the binding constraint: past Saturday 13 February there is no room for a retake before the 3 March expiry. |
| The lab build overruns 13 Dec | Do Essential Commands and Users from the notes on the Mac, and build the VMs the following weekend. Only the hands-on questions need the lab. |
| Under 10 hours a week in January | Drop KodeKloud mocks 3 and 4. Keep all three repo mocks and both killer.sh sessions; they are the highest-yield hours. |
| A domain is still weak on 31 Jan | Move the exam to Saturday 13 February at the latest, and no further. Beyond that a single bad result ends the attempt, because the retake would fall after the 3 March expiry. |
