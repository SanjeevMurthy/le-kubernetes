# LFCS (Linux Foundation Certified System Administrator) — Deep Research Report

**Prepared:** 2026-09-06
**Purpose:** Evidence base for building an LFCS preparation kit (study notes, practice tasks, mock exams, a bash practice CLI that runs inside a Linux VM, and a study plan) for a candidate who already holds CKA and CKAD, is comfortable on the command line, holds an LFCS voucher expiring March 2027, and is pursuing the Golden Kubestronaut track.

**Tagging convention used throughout**
- **OFFICIAL** — Linux Foundation / CNCF / killer.sh (the LF-contracted simulator vendor) pages.
- **CANDIDATE-REPORTED** — blogs, forum posts, GitHub notes, videos, third-party training sites.
- **INFERRED** — my synthesis from the above.

**Method and known gaps.** Roughly 45 distinct web searches and 90+ page fetches were run. Official LF pages were fetched in full (the Important Instructions page was downloaded as raw Markdown). Reddit blocked all automated access (both `reddit.com` search and `old.reddit.com` returned HTTP 403 "blocked due to a network policy"), so **no Reddit threads are cited**; the candidate write-ups below come from Medium, dev.to, personal/company blogs, the Linux Foundation Forums, the KodeKloud community, and YouTube. Udemy and O'Reilly course pages also blocked automated fetches (403), so ratings for those are taken from search-result snippets only where noted. The LF "LFCS Sample Curriculum Path" PDF (`/wp-content/uploads/2024/10/LFCS_CurriculumPath_102024a.pdf`) returned HTTP 404. The killer.sh site requires JavaScript; its content was retrieved through a reader proxy and is quoted from that.

---

## 0. Headline findings (one-screen summary)

| Item | Finding | Tag / source |
|---|---|---|
| Current curriculum version | The **five-domain "distribution-agnostic" curriculum introduced 11 May 2023 12:01 AM UTC** is still the current one in September 2026. No later revision has been announced. | OFFICIAL — https://training.linuxfoundation.org/blog/updated-linux-foundation-certified-system-administrator-lfcs-exam/ |
| Domains and weights | Operations Deployment 25%, Networking 25%, Storage 20%, Essential Commands 20%, Users and Groups 10% | OFFICIAL — https://training.linuxfoundation.org/certification/linux-foundation-certified-sysadmin-lfcs/ |
| Format | Online, proctored (PSI Bridge / PSI Secure Browser), **17–20 performance-based tasks, 2 hours, pass mark 67%** | OFFICIAL — https://docs.linuxfoundation.org/tc-docs/certification/instructions-lfcs-and-lfce |
| Distribution | **Not stated officially.** LF says the exam is "independent of distribution-specific tasks" and platform selection is "no longer required". Candidate evidence points to Ubuntu-based nodes, possibly with RHEL-family nodes; no source confirms "Ubuntu 24.04" specifically. | OFFICIAL + CANDIDATE-REPORTED (see §1.3) |
| Environment | Base host (`hostname base`, must not be rebooted) → `ssh <nodename>` to a designated host per task; nested SSH unsupported; `sudo -i` available; vim/nano/emacs/git/sudo on every SSH host | OFFICIAL — Important Instructions (same URL) |
| Allowed docs | Man pages, `/usr/share` docs, distribution packages — **only if accessible from within the terminal**; no browser documentation | OFFICIAL — Important Instructions |
| Retakes / eligibility / validity | 1 free retake within 12 months of purchase; no enforced wait; cert valid **24 months** (for exams taken from 1 Apr 2024) | OFFICIAL — https://training.linuxfoundation.org/about/policies-2-2026/certification-exam-retake-policy/ ; https://training.linuxfoundation.org/certification-policy-change-2024/ |
| Simulator | Two killer.sh LFCS sessions (36 h each, identical 20-question content) included with the exam purchase; excluded only for the India voucher scheme per a community FAQ | OFFICIAL — https://linuxfoundation.atlassian.net/wiki/spaces/TCCS/pages/161579396 ; CANDIDATE-REPORTED — https://github.com/kodekloudhub/community-faq/blob/main/docs/killer-sh.md |
| Most-reported exam task | **iptables/nftables packet filtering, redirection and persistence** (7 distinct exam reports), followed by LVM, OpenSSL certificate inspection, and containers | CANDIDATE-REPORTED (see §3) |
| Most-recommended resource | KodeKloud LFCS course + its mock exams (10 of the write-ups), then killer.sh (6), Ghada Atef's Udemy practice exams + lab scripts, Sander van Vugt's video course, LFS207 | CANDIDATE-REPORTED (see §2, §4) |

---

## 1. Official exam facts

### 1.1 Curriculum version and history

- The **current curriculum took effect at 12:01 AM UTC on 11 May 2023** "for anyone sitting for the exam" after that time, including retakes. The LF blog says the exam "is now independent of distribution-specific tasks so you no longer have to select a platform in the exam preparation checklist" and lists the five domains with weights: Operations and Deployment 25%, Storage 20%, Networking 25%, Users & Groups 10%, Essential Commands 20%. **OFFICIAL** — https://training.linuxfoundation.org/blog/updated-linux-foundation-certified-system-administrator-lfcs-exam/
- The revision was originally scheduled for **February 2023**: an LF forum thread from November 2022 explains that the new course LFS207 "covers domains and competencies of the upcoming LFCS (scheduled for February 2023 update)" while LFS201 covered the old version. **OFFICIAL (LF staff reply on LF forum)** — https://forum.linuxfoundation.org/discussion/862448/lfs201-vs-lfs207
- The premise that the revision happened "around 2024" is therefore slightly off: the revision shipped in **May 2023**; what happened in **January 2024** was that training vendors (e.g. KodeKloud) caught up — a KodeKloud community post of 4 Jan 2024 notes three sub-competencies newly listed under Operations Deployment that were missing from course material: "Recover from hardware, operating system, or filesystem failures", "Manage Virtual Machines (libvirt)", "Configure container engines, create and manage containers". **CANDIDATE-REPORTED** — https://kodekloud.com/community/t/updated-lfcs-exam-objectives/405357
- **The previous (pre-May-2023) curriculum** had six domains: Essential Commands 25%, Operation of Running Systems 20%, User and Group Management 10%, Networking 12%, Service Configuration 20%, Storage Management 13%. This is documented in the LF "Certification Preparation Guide, October 2018" PDF, which also states the exam was then "Distro-flexible – You can take the certification exam in CentOS or Ubuntu". **OFFICIAL (historical)** — https://resources.linuxfoundation.org/LF+Training/LF_Training_WP_CertificationPrepGuide_October2018+(6).pdf
- **Warning for kit design:** many pages that rank highly for "LFCS 2026" still print the *old* six-domain list (e.g. sailor.sh's "LFCS Exam Guide 2026" dated 25 May 2026 lists Essential Commands 25% / Operation of Running Systems 20% / Service Configuration 20% / Storage 13% / Networking 12% / Users 10% and says candidates "select from Ubuntu, openSUSE, or CentOS Stream"; CertLand's March 2026 guide and adamdjellouli.com's notes, last modified 27 Apr 2026, do the same and quote a 66% pass mark, $395 price and 3-year validity). Treat these as **stale**. **CANDIDATE-REPORTED** — https://sailor.sh/blog/lfcs-exam-guide-2026/ ; https://certland.net/blog/linux-foundation-certified-system-administrator-lfcs-study-guide-2026/ ; https://adamdjellouli.com/articles/linux_notes/lfcs
- **Nothing has been announced for late 2026.** A search of `training.linuxfoundation.org` blog posts for 2025–2026 mentioning LFCS finds only a career profile ("Meet Luis Felipe Hernandez: LFCS, CKAD", 19 Nov 2025), a holiday promotion (16 Dec 2025) and a trends post (22 Jan 2025) — no curriculum or environment change notice. **OFFICIAL** — https://training.linuxfoundation.org/blog/meet-luis-felipe-hernandez/ ; https://training.linuxfoundation.org/blog/unwrap-new-skills-this-season/ ; https://training.linuxfoundation.org/blog/2025-top-10-it-training-certification-trends/ . The KodeKloud Udemy course, "last updated July 2026", still teaches the same five domains. **CANDIDATE-REPORTED** — https://www.udemy.com/course/linux-foundation-certified-systems-administrator-lfcs/
- A Japanese-language variant, **LFCS-JP**, exists as a separate product page. **OFFICIAL** — https://training.linuxfoundation.org/certification/linux-foundation-certified-system-administrator-lfcs-jp/

### 1.2 Domains, weights and every sub-topic bullet (verbatim)

Source: LFCS product page, "Domains & Competencies" section. **OFFICIAL** — https://training.linuxfoundation.org/certification/linux-foundation-certified-sysadmin-lfcs/

**Operations Deployment — 25%**
- Configure kernel parameters, persistent and non-persistent
- Diagnose, identify, manage, and troubleshoot processes and services
- Manage or schedule jobs for executing commands
- Search for, install, validate, and maintain software packages or repositories
- Recover from hardware, operating system, or filesystem failures
- Manage Virtual Machines (libvirt)
- Configure container engines, create and manage containers
- Create and enforce MAC using SELinux

**Networking — 25%**
- Configure IPv4 and IPv6 networking and hostname resolution
- Set and synchronize system time using time servers
- Monitor and troubleshoot networking
- Configure the OpenSSH server and client
- Configure packet filtering, port redirection, and NAT
- Configure static routing
- Configure bridge and bonding devices
- Implement reverse proxies and load balancers

**Storage — 20%**
- Configure and manage LVM storage
- Manage and configure the virtual file system
- Create, manage, and troubleshoot filesystems
- Use remote filesystems and network block devices
- Configure and manage swap space
- Configure filesystem automounters
- Monitor storage performance

**Essential Commands — 20%**
- Basic Git Operations
- Create, configure, and troubleshoot services
- Monitor and troubleshoot system performance and services
- Determine application and service specific constraints
- Troubleshoot diskspace issues
- Work with SSL certificates

**Users and Groups — 10%**
- Create and manage local user and group accounts
- Manage personal and system-wide environment profiles
- Configure user resource limits
- Configure and manage ACLs
- Configure the system to use LDAP user and group accounts

**INFERRED notes on the bullets.** (a) "Create and enforce MAC using SELinux" names SELinux explicitly, not AppArmor — a strong hint that at least one RHEL-family node exists or that SELinux tooling is expected. (b) "Use remote filesystems and network block devices" covers NFS *and* NBD; KodeKloud's Mock Exam 3 indeed has an `nbd-client` task (see §3). (c) Classic Linux basics (permissions, find, archives, text processing, redirection) no longer appear as named bullets but are implicitly required by every other task — several candidates still report them.

### 1.3 Distribution and version used in the exam environment

- **Official position:** "The exam is independent of distribution-specific tasks, therefore selecting a platform in the exam preparation checklist is no longer required." The Important Instructions page does not name any distribution or version; it only says candidates who install packages "will want to be familiar with standard package managers (apt, dpkg, dnf, and yum)". **OFFICIAL** — https://training.linuxfoundation.org/certification/linux-foundation-certified-sysadmin-lfcs/ ; https://docs.linuxfoundation.org/tc-docs/certification/instructions-lfcs-and-lfce
- When asked "On which OS did you take your LFCS exam? Was is CentOS Stream or Ubuntu?" on the LF forum (June–July 2025), LF staff (Flavia) declined to answer and redirected to the Candidate Handbook, Important Instructions, FAQs and Customer Support. **OFFICIAL (non-answer)** — https://forum.linuxfoundation.org/discussion/869018/on-which-os-did-you-take-your-lfcs-exam
- KodeKloud staff (Rob), Nov 2024, when asked what `cat /etc/*-release` shows on exam machines: "typically Ubuntu is used, though this isn't formally stated", adding that "there may be CentOS nodes included" to honour distribution independence. **CANDIDATE-REPORTED** — https://kodekloud.com/community/t/lfcs-exam-os-2024/468650
- Dave Watts (passed 86/100, March 2024) says the May 2023 update made the exam "distroless" but "a bit more vague", and he deliberately practised on both Rocky 8 and Ubuntu (firewall-cmd vs ufw, dnf vs apt). **CANDIDATE-REPORTED** — https://medium.com/@wattsdave/linux-foundation-certified-systems-administrator-lfcs-navigating-the-study-journey-for-the-lfcs-06d9e2aa5165
- Kienlt (passed 86/100, Dec 2025) prepared on Ubuntu 22.04 libvirt VMs and used `ubuntu22.04` as the os-info parameter in `virt-install` examples; the article does not state that the exam nodes themselves were 22.04. **CANDIDATE-REPORTED** — https://medium.com/@kienlt.qn/prepare-for-linux-foundation-certified-system-administrator-lfcs-09aee7616664
- The KodeKloud mock exams (the resource candidates most often call "closest to the real exam") use Ubuntu conventions: `ssh bob@node01`, `netplan try`, `nbd-client`. **CANDIDATE-REPORTED** — https://kodekloud.com/community/t/lfcs-mock-exam-3/497175 ; https://kodekloud.com/community/t/lfcs-mock-exam-3-question-17/500701
- The KodeKloud course itself uses "Ubuntu as the primary distribution" for demos and labs. **CANDIDATE-REPORTED** — https://www.udemy.com/course/linux-foundation-certified-systems-administrator-lfcs/
- **No source found — official or candidate — that states the exam runs Ubuntu 24.04.** Claims on third-party 2026 study-guide sites that you "choose Ubuntu or CentOS Stream at scheduling" reflect the pre-2023 exam. **INFERRED conclusion:** build the practice kit primarily on **Ubuntu (24.04 LTS, with awareness of 22.04 differences)** using netplan/ufw/apt, and add a **RHEL-family track (Rocky 9 / CentOS Stream 9)** for dnf, firewalld, NetworkManager/nmcli, SELinux — the curriculum's explicit SELinux bullet and LF's "may be CentOS nodes" hedge make a RHEL-family node plausible.

### 1.4 Duration, tasks, passing score, results, retakes, validity, price

| Fact | Value | Tag / source |
|---|---|---|
| Tasks | "The exams consist of 17-20 performance-based tasks." | OFFICIAL — https://docs.linuxfoundation.org/tc-docs/certification/instructions-lfcs-and-lfce |
| Duration | "The exams are expected to take 2 hours to complete." | OFFICIAL — same |
| Passing score | "For the LFCS Exam, a score of 67% or above must be earned to pass." (older candidate posts say 66%) | OFFICIAL — same |
| Results | "A score report will be sent to the candidate via email within 24 hours" | OFFICIAL — https://training.linuxfoundation.org/about/faqs/certification-faq/ |
| Retake | "One (1) retake per Exam purchase will be granted ... The retake must be taken within 12 months of the date of the original Exam purchase, or before your corporate subscription expires (whichever happens first)." Exams marked SINGLE-ATTEMPT and SkillCred exams get no retake. Page last modified 24 Oct 2024. | OFFICIAL — https://training.linuxfoundation.org/about/policies-2-2026/certification-exam-retake-policy/ |
| Wait period | "There is no enforced wait period for retakes currently." Retake eligibility requires a "No Pass" grade (scoring takes 24 h). | OFFICIAL — https://training.linuxfoundation.org/about/faqs/certification-faq/ |
| Retake mechanics | Candidate clicks "Claim Your Retake"; a rescoring request (fee) is possible up to 2 days after the score report, not for MC/SkillCred exams | OFFICIAL — https://docs.linuxfoundation.org/tc-docs/certification/lf-handbook2/exam-scoring-and-notification/exam-results-no-pass |
| Eligibility window | "12-months to schedule & take the exam"; "Two exam attempts" | OFFICIAL — https://training.linuxfoundation.org/certification/linux-foundation-certified-sysadmin-lfcs/ |
| Validity | "Certifications become non-current (expire) 24 months from the date that a certificant successfully passes"; renew by retaking and passing the same exam before expiry | OFFICIAL — https://docs.linuxfoundation.org/tc-docs/certification/lf-handbook2/certificates-and-certification |
| Validity change date | 36 → 24 months "starting for exams taken April 1, 2024, 00:00 UTC"; earlier passes keep 36 months | OFFICIAL — https://training.linuxfoundation.org/certification-policy-change-2024/ |
| Price | Exam only $445; Exam + THRIVE-ONE subscription $625; Exam + LFS207 course $645; "no prerequisites"; level "Intermediate" | OFFICIAL — https://training.linuxfoundation.org/certification/linux-foundation-certified-sysadmin-lfcs/ |
| Price effective date | $445 effective 4 Feb 2025 (LF pricing announcement) | OFFICIAL — https://training.linuxfoundation.org/blog/new-certification-pricing/ |
| Score breakdown | Candidates get an overall score only; a 2023 forum poster who completed 16 of 17 tasks with "2–3 partial errors" still failed twice and complained about lack of per-task feedback | CANDIDATE-REPORTED — https://forum.linuxfoundation.org/discussion/855771/anyone-fail-lfcs |

Note: several third-party sites claim "starting August 1st, 2025 the LFCS is valid for two years". No LF page says this; the official policy is the 1 April 2024 cut-over above. Treat the August-2025 date as **unverified**.

### 1.5 Allowed documentation

Verbatim from the Important Instructions (**OFFICIAL** — https://docs.linuxfoundation.org/tc-docs/certification/instructions-lfcs-and-lfce):

> The following tools and resources are allowed during the Exam as long as they are used by Candidate to work independently on exam tasks (i.e. not used for 3rd party assistance or research) and are accessed from within the Linux server terminal on which the Exam is delivered (resources that cannot be accessed from within the terminal are not allowed):
> - Man pages
> - Documents installed by the distribution (i.e. /usr/share and its subdirectories)
> - Packages that are part of the distribution (may also be installed by Candidate if not available by default)
> *If you decide to install packages (not required to complete tasks) to your exam environment, you will want to be familiar with standard package managers (apt, dpkg, dnf, and yum)*

- Unlike CKA/CKAD, there is **no browser-based documentation** for LFCS. The generic ExamUI page describes a Firefox browser "to access Resources Allowed", but the LFCS-specific rule above restricts resources to what is reachable inside the terminal. **OFFICIAL** — https://docs.linuxfoundation.org/tc-docs/certification/lf-handbook2/exam-user-interface/examui-performance-based-exams
- Candidates confirm: "Unlike other hands-on exams, candidates cannot access online manuals during testing" (Mamezou, exam 28 Dec 2025); "Man pages are your only reference" (KodeKloud guide); wattsdave deliberately avoided `tldr`/`cht.sh` because their availability is uncertain. **CANDIDATE-REPORTED** — https://developer.mamezou-tech.com/en/blogs/2026/01/12/golden-kubestronaut/ ; https://kodekloud.com/blog/the-complete-lfcs-study-guide-for-system-administrator-certification/ ; https://kodekloud.com/community/t/lfcs-study-and-exam-tips/464199

### 1.6 Exam environment details (verbatim where it matters)

From the Important Instructions (**OFFICIAL** — https://docs.linuxfoundation.org/tc-docs/certification/instructions-lfcs-and-lfce):

- Proctoring: "The online proctored exam is taken on PSI proctoring platform 'Bridge', using the PSI Secure Browser"; "proctored remotely via streaming audio, video, and screen sharing feeds."
- Hardware: "One active monitor (either built in or external) (NOTE: Dual Monitors are NOT supported)"; LF "recommends a screen size of 15" or higher" and "a screen resolution of 1080p"; microphone and movable webcam required; avoid work-provided devices.
- Environment:
  - "You **must not** reboot the base system (hostname base). Rebooting the base system will **not** restart your exam environment."
  - "You must complete each task in this exam on a designated *host*. An infobox at the start of each task provides you with instructions to ssh into the designated host."
  - "Hosts can be reached via ssh, using a command such as the following: `ssh <nodename>`"
  - "Once you have completed a task, exit the ssh session to return to the base system (hostname base)."
  - "Nested SSH is not supported - always return to the base system first before connecting to another host: `exit`"
  - All SSH hosts have "Emacs, Git, Nano, Sudo, vim" pre-installed; "The base system (hostname base) does not have any of the above tools pre-installed as all tasks on this exam must be completed on a designated ssh host."
- Technical instructions:
  - "You can assume elevated privileges on any host by issuing the following command: `sudo -i`"
  - "Do not stop or tamper with the certerminal process as this will END YOUR EXAM SESSION."
  - "Do not block incoming ports 8080/tcp, 4505/tcp and 4506/tcp. This includes firewall rules that are found within the distribution's default firewall configuration files as well as interactive firewall commands." (**INFERRED:** 4505/4506 are SaltStack master ports, so grading/orchestration almost certainly uses Salt — a firewall task that drops these ports can break grading.)
  - "Use Ctrl+Alt+W instead of Ctrl+W."
  - Terminal copy/paste: Ctrl+Shift+C / Ctrl+Shift+V; other desktop apps: Ctrl+C / Ctrl+V.
  - "For security reasons, the INSERT key is prohibited within the Remote Desktop" — use `i` in vim.
  - An on-screen "Virtual Keyboard" exists for special characters.
  - "Installation of services and applications included in this exam may require modification of system security policies to successfully complete." (**INFERRED:** expect SELinux booleans/contexts or firewall changes to be part of a service task.)
- Generic ExamUI facts (**OFFICIAL** — https://docs.linuxfoundation.org/tc-docs/certification/lf-handbook2/exam-user-interface/examui-performance-based-exams): the console shows a ReadMe tab and a Remote Desktop tab; a Linux Terminal Emulator is in the Applications menu / desktop icon; VSCodium is available "with its integrated terminal as an alternative", extensions cannot be installed; timer alerts at 30, 15 and 5 minutes; "there is no way to ADD time back to the timer in the event of a system disconnect"; font size and window size are adjustable.
- The killer.sh simulator replicates "a very similar Remote Desktop interface" with an XFCE desktop (**OFFICIAL / killer.sh** — https://killer.sh/faq), and a 2024 candidate describes the PSI screen as "a small screen and difficult copy-paste functionality", "less user friendly compared with Pearson". **CANDIDATE-REPORTED** — https://medium.com/@christinacc/linux-foundation-certified-systems-administrator-lfcs-journey-0e97b2326a56
- **Number of machines / multi-host tasks:** Rafael Medeiros (second attempt, May 2025) reports "17 questions across 17 machines (one per task)" and lost points on his first attempt by "completing one or two questions on the wrong host". killer.sh states each simulator question runs "in its own encapsulated virtual machine". **CANDIDATE-REPORTED / killer.sh** — https://rafaelmedeiros94.medium.com/how-i-passed-the-lfcs-exam-real-advice-from-my-second-attempt-98d5bf433b8f ; https://killer.sh/lfcs . **INFERRED:** tasks are single-host by default, but a task's host can have its own peer (e.g. an NFS or NBD server) as in KodeKloud Mock Exam 3.
- **Rules of the room** (**OFFICIAL** — https://docs.linuxfoundation.org/tc-docs/certification/lf-handbook2/exam-rules-and-policies): quiet private well-lit room, desk clear of notes and electronics, no other person present, no earpieces/wearables, no communication with anyone but the proctor.

### 1.7 Voucher and simulator inclusion

- Product page "What's included": "12-months to schedule & take the exam", "Access to two exam simulation attempts", "Two exam attempts", "Exam Simulator", "PDF Certificate and Digital Badge", "Certification Valid for 2 Years". Simulator text: "You will have two simulation attempts (36 hours of access for each attempt from the start of activation)... 20-25 questions that are exactly the same for every attempt and every user, unlike the actual exam". **OFFICIAL** — https://training.linuxfoundation.org/certification/linux-foundation-certified-sysadmin-lfcs/
- LF support article: eligible exams are "CKA, CKAD, CKS, LFCS, LFCT"; access via trainingportal.linuxfoundation.org → Start/Resume → "Preparing for the Exam" → "Exam Simulator"; "The simulators do not 100% replicate the exam environment" but give the same type of tasks with detailed solutions. **OFFICIAL** — https://linuxfoundation.atlassian.net/wiki/spaces/TCCS/pages/161579396/How+do+I+access+the+exam+simulator+Practice+Exams
- Simulators were added to LFCS on 13 Sep 2023 (blog "Certification Exam Simulators Now Included"). **OFFICIAL** — https://training.linuxfoundation.org/blog/exam-simulators/
- killer.sh FAQ: "If you purchased the CKA|CKS|CKAD|CNPE|LFCS exam, two simulator sessions are already included"; LFCS has 20 questions; the two sessions "have the same questions"; standalone price "29.99 USD for two LFCS sessions". **OFFICIAL / killer.sh** — https://killer.sh/faq
- Exclusion: the KodeKloud community FAQ states killer.sh is included with the standard purchase, "however, if you purchased using the voucher scheme for residents of India, this is not the case." **CANDIDATE-REPORTED** — https://github.com/kodekloudhub/community-faq/blob/main/docs/killer-sh.md
- The Golden Kubestronaut Bundle page ($4,229, 16 certifications including LFCS) does not itemise simulator access. **OFFICIAL** — https://training.linuxfoundation.org/certification/golden-kubestronaut-bundle/ . **INFERRED:** a standard LF voucher redeemed in the training portal should show the "Exam Simulator" button; verify in the portal rather than assume.

### 1.8 Golden Kubestronaut context

- "To become a Golden Kubestronaut, you need to pass all CNCF certifications and LFCS", and "All certifications must be current (i.e. in good standing, not expired.)" at application. **OFFICIAL** — https://www.cncf.io/training/kubestronaut/kubestronaut-faq/
- CNPA became mandatory 15 Oct 2025 and CNPE on 1 Mar 2026; "As new CNCF certifications are introduced, they will also be added." **OFFICIAL** — https://training.linuxfoundation.org/resources/kubestronaut-program/
- Because LFCS is valid 24 months and all certs must be current simultaneously, the **timing** of LFCS relative to the other 15 exams matters (**INFERRED**). A community learning path places LFCS first in the "Golden" phase (**CANDIDATE-REPORTED** — https://golden-kubestronaut-learning.readthedocs.io/), while KodeKloud's path places it after the core Kubernetes exams (**CANDIDATE-REPORTED** — https://kodekloud.com/learning-path/golden-kubestronaut/). KodeKloud ran a live "Golden Kubestronaut Kickoff: LFCS Exam Prep & Requirements" session on 25 Sep 2025 (hosts Michael and Sanjeev). **CANDIDATE-REPORTED** — https://www.youtube.com/watch?v=Nn83r7PrYZI

---

## 2. Candidate exam-experience write-ups (2020–2026)

Twenty-one distinct write-ups/threads were located and read (Reddit was inaccessible — see Method). The table lists what each source actually states; blank cells mean the source did not say.

| # | Source (URL) | Date | Outcome | Prior Linux experience | Study time | Resources | What surprised them | Top tips |
|---|---|---|---|---|---|---|---|---|
| 1 | Pierretenrique, Medium — https://medium.com/@pierretenrique/how-i-passed-the-lfcs-with-6-months-of-linux-experience-d4d4f869cd6b | 4 Jan 2026 | Pass | ~6 months home-lab | — | KodeKloud (videos, labs, mock exams), killer.sh (both sessions), Linux Bible, UNIX & Linux Sysadmin Handbook (Part 4), an RHCSA book, Ghada Atef's Udemy practice exams | "17 performance-based questions" | 3 VirtualBox VMs to practise NFS, SSH keys, Apache, cron; "build-install-break-repair cycle"; master `find -exec`, OpenSSL, Docker, Git, NFS, SSH, Apache, cron; use `man`/`tldr` |
| 2 | Emmanuel Odenyire, Medium — https://eodenyire.medium.com/how-i-passed-the-lfcs-a-sysadmins-guide-to-conquering-the-linux-foundation-exam-b3e2e8e919fa | Posted 14 Nov 2025; exam 16 Aug 2024 | Pass | Working sysadmin | — | KodeKloud (Udemy/LinkedIn Learning), Pearson/Sander van Vugt Coursera specialization, own VirtualBox/KVM lab with 2–3 CentOS/Ubuntu servers | Single words in prompts decide pass/fail | Master vi; read prompts meticulously; use man pages; prioritise high-value tasks; verify each task |
| 3 | Dave Watts, Medium — https://medium.com/@wattsdave/linux-foundation-certified-systems-administrator-lfcs-navigating-the-study-journey-for-the-lfcs-06d9e2aa5165 (also LF-forum-style thread https://kodekloud.com/community/t/lfcs-study-and-exam-tips/464199) | 26 Mar 2024 | Pass, 86/100 | — | ~2 weeks of repeated practice exams at the end | KodeKloud Udemy (primary), A Cloud Guru (secondary), killer.sh, personal GitLab notes; Rocky 8 + Ubuntu VMs | Exam became "distroless" and "a bit more vague"; "Killer.sh is harder than the exam"; 17 questions, "no weightings on questions" | Practise both RHEL and Debian families; pipe `--help` into `less`; `man openssl-x509`; avoid tldr/cht.sh |
| 4 | Rafael Medeiros, Medium — https://rafaelmedeiros94.medium.com/how-i-passed-the-lfcs-exam-real-advice-from-my-second-attempt-98d5bf433b8f | 19 May 2025 | Fail → Pass | — | — | KodeKloud mock exams, killer.sh | 17 questions on 17 machines; failed first time by doing 1–2 tasks on the wrong host; iptables "a heavy question" | Use only one killer.sh session before the exam (keep one for a retake); take the exam in the morning; verify the SSH target; vim shortcuts; `apropos` |
| 5 | Christina, Medium — https://medium.com/@christinacc/linux-foundation-certified-systems-administrator-lfcs-journey-0e97b2326a56 | 12 Mar 2024 | Fail → 65 → Pass 81 (3rd attempt) | — | 1.5-month gap between attempts | KodeKloud Udemy course, 32 labs + 4 mock exams "multiple times", killer.sh "until 75/75", GitHub notes | PSI platform less friendly than Pearson; small screen, awkward copy-paste | iptables task: create rules, delete, recreate "with more parameters", make permanent, verify across servers; slow down with man pages; don't take long breaks after failing |
| 6 | Okpallannuozo Nnaemeka, Medium — https://okpallannaemeka.medium.com/a-short-guide-to-acing-the-linux-foundation-certified-system-administrator-lfcs-exam-2db4518931e6 | 31 Dec 2020 | Pass | "basic Linux commands" | 6 months, ~10 h/week initially | LFS201, UNIX & Linux Sysadmin Handbook 5e, Linux+ guide, Sander van Vugt course, ravikirans.com guide; cloud VMs | Terminal slowness from network; small terminal, no multiplexer | Schedule the exam mid-way to force momentum; labs in the cloud (decommission after) |
| 7 | W. Jenks Gibbons, Medium — https://medium.com/@jenksgibbons/linux-foundation-certified-systems-administrator-lfcs-learnings-and-preparation-guide-7ae888da9635 | 2 Oct 2023 | Pass | — | — | Found LFCS material "difficult to find, low-quality or non-representative" compared with K8s | "about 17 to 22 non-multiple-choice questions on various virtual machines" | — |
| 8 | Arun Pal, dev.to — https://dev.to/arunpal_/how-do-i-score-85100-on-my-first-attempt-in-lfcs-exam-4p9o | 12 Feb 2022 | Pass, 85/100 | DevOps engineer | ~3 months part-time | LF Cloud Engineer Bootcamp (LFS201/LFS211), official practice-question doc, man pages | Left 2 questions unattempted (time) | "`man -k <keyword>` is your go to guy"; "Don't stick on a single question for more than 5-7 mins"; practise on VMs |
| 9 | Cloudeteer Engineering — https://engineering.cloudeteer.de/blog/2025/passing-the-linux-foundation-certified-systemsadministrator-certification-in-2.5-days/ | 15 Jul 2025 | Pass, 90% | Former Ubuntu server admin, CKA holder, daily Linux user | 25 h over 2.5 days (9 h lectures, 8.5 h labs, 2 h mock, 2 h killer.sh) | KodeKloud Udemy (~$15), ChatGPT, official docs, killer.sh | killer.sh "barely finished the 23 tasks"; "Calling this Exam 'A little harder than the actual exam' is the understatement of the century"; real exam simpler than the KodeKloud mock; PSI stable | "look at the difference between iptables and nftables and how to persist them"; KodeKloud lacked labs for LDAP, timesync, proxy/load balancer, iptables |
| 10 | Mamezou Developer Portal — https://developer.mamezou-tech.com/en/blogs/2026/01/12/golden-kubestronaut/ | 12 Jan 2026; exam 28 Dec 2025 | Pass | Kubernetes-certified engineer | 15 days | Udemy KodeKloud course, Killercoda, killer.sh (twice), libvirt VMs on Ubuntu | Cannot refer to online manuals; simulator "slightly harder than the real exam" | Master man navigation; tab completion to find commands; read "SEE ALSO"; grep `/etc` for config files |
| 11 | Kienlt, Medium — https://medium.com/@kienlt.qn/prepare-for-linux-foundation-certified-system-administrator-lfcs-09aee7616664 | 30 Dec 2025 | Pass, 86/100 | Elasticsearch/Kafka/MongoDB on OpenStack; gaps in Linux basics | 2 days | KodeKloud mock exams, man pages (`man netplan`), Ubuntu 22.04 libvirt VMs | "considered easy to pass because it requires only 67" | Topic list: IO redirection, LVM, ACLs, RAID 1, SUID/SGID/sticky, resource limits, fallocate + swap, libvirt VMs, process IO monitoring, SELinux, bridge networking, iptables, OpenSSL |
| 12 | tectrack.net — https://www.tectrack.net/how-i-passed-lfcs-linux-foundation-certified-system-administrator-10-tips-and-tricks-to-pass-lfcs/ | 12 Jul 2023 | Fail 48% → Pass 75% | Systems engineer (virtualisation/cloud) | ~2 months, then 4 days + 2 days of mocks before retake | LF official course (subscription), KodeKloud Udemy Business, LF PDFs, KodeKloud mocks | Terminal on right, questions on left; wanted a 24–27" monitor | "PRACTICE!!!"; learn `man`, `tldr`, `--help`; use root; one-liners for multi-file tasks; "return to base machine after SSH work" |
| 13 | QAInsights — https://qainsights.com/surviving-and-thriving-in-the-lfcs-exam-a-personal-journey/ | 23 Dec 2024 | Pass | Advanced | — | LF guidelines, a GitHub repo of commands/sample questions, man pages | "time flies" | Easy questions first; 5–7 min per question; Ctrl+R history; check `/var/log`; practise without a GUI; verify work |
| 14 | LF Forum "Just Passed Linux-Foundation LFCS" — https://forum.linuxfoundation.org/discussion/868280/just-passed-linux-foundation-lfcs | Jan 2025 (cutefirebreaker); Jul 2025 (cummingsmith) | Pass ×2 | — | — | cummingsmith cites "P2PExams practice questions" (a dump site — treat with caution) | Ops Deployment and Networking "the trickiest" | — |
| 15 | KodeKloud community "I ve sucessflully passed the lfcs exam" (enrique_ops) — https://kodekloud.com/community/t/i-ve-sucessflully-passed-the-lfcs-exam/492749 | 6 Jan 2026 | Pass | — | — | KodeKloud labs | iptables, NFS and web servers "can be tricky in real exam conditions" | Use both attempts; treat the first as familiarisation if needed |
| 16 | KodeKloud community "Hey! I finally made it..." (Jarosław Bagnicki) — https://kodekloud.com/community/t/hey-i-finally-made-it-and-pass-the-lfcs-exam-for-sure/241305 | 20 Dec 2022 | Pass | Not a daily Linux admin | — | KodeKloud course + mock exams | Skipped 3 tasks for time; 2 h "insufficient if not working with Linux daily" | Mocks mirror the real format |
| 17 | LF Forum "Anyone fail LFCS?" — https://forum.linuxfoundation.org/discussion/855771/anyone-fail-lfcs | Nov 2020 – Aug 2023 | Multiple fails | why2: LFS211 student; avmentzer: "completely new to Linux", passed 2nd try; christopherbrian failed twice (time); branko.dosenovic failed twice (16/17 attempted) | — | LFS201/LFS211 | Docker deployment question not covered by course; ~17 tasks; no per-task feedback | Moderator: use `--help`/`man`, not memorised lists; linuxcommand.org for bash |
| 18 | LF Forum "A very bad exam experience" — https://forum.linuxfoundation.org/discussion/859058/a-very-bad-exam-experience | May 2021 – Nov 2023 | Fails/technical | — | — | — | Browser hangs, console resets, 4+ hour session; alakananda scored 59% and could only attempt 15 questions | Open a support ticket; expect several business days |
| 19 | LF Forum "LFCS exam tips" (aimcorp) — https://forum.linuxfoundation.org/discussion/860093/lfcs-exam-tips | Oct 2021 (passed Mar 2021) | Pass | — | — | Own VMs/old hardware, cloud free tiers, Termux on phone | — | Practise LVM/RAID, partitions, several filesystems, iptables and nftables, `ip`/`nmcli`, AppArmor and SELinux, permissions, piping/redirection, `/proc` |
| 20 | Alonso Parasxidis (Golden Kubestronaut), Medium — https://medium.com/@alonso.parasxidis/from-zero-to-golden-kubestronaut-my-journey-through-the-cncf-certification-landscape-7dca2de22674 | 7 Oct 2025 | Pass (implied) | Strong K8s | — | — | "Man pages are allowed, but you need quick muscle memory" | Take LFCS early if your Linux is strong, else later |
| 21 | Willem Berroubache (Golden Kubestronaut), Medium — https://medium.com/@willemberroubache/the-road-to-golden-kubestronaut-surviving-16-cncf-certifications-cd8d53524362 | 3 Dec 2025 | Pass (implied) | — | — | — | "A practical test of your Linux administration reflexes", pass mark 67% | — |

Older reference: jeffran (LF Forum, Oct 2017) failed twice amid platform outages and complained that some questions were "obfuscated" about whether tools had to be installed. **CANDIDATE-REPORTED** — https://forum.linuxfoundation.org/discussion/474345/my-lfcs-exam-experience

### 2.1 Synthesis — most recommended resources (count of write-ups above that used/recommended them)

| Resource | Mentions | Sources |
|---|---|---|
| KodeKloud LFCS course and/or its mock exams | 10 | #1, #2, #3, #4, #5, #9, #10, #11, #12, #15, #16 |
| killer.sh simulator | 6 | #1, #3, #4, #5, #9, #10 |
| Own multi-VM lab (VirtualBox/KVM/libvirt/cloud) | 7 | #1, #2, #3, #6, #8, #10, #11, #19 |
| Sander van Vugt (Pearson/O'Reilly/Coursera) | 2 | #2, #6 |
| LF courses LFS201/LFS207/LFS211 | 4 | #6, #8, #12, #17 |
| Ghada Atef Udemy practice exams | 1 | #1 |
| Books (Linux Bible; UNIX & Linux Sysadmin Handbook) | 2 | #1, #6 |
| Killercoda | 1 | #10 |
| Dump/"practice question" sites (P2PExams, Pass4sure) | 2 | #14 and a reply in #16 — **not recommended**; MCQ-style dumps do not match a performance exam and violate the LF certification agreement (https://docs.linuxfoundation.org/tc-docs/certification/lf-cert-agreement) |

### 2.2 Synthesis — common time-management advice

- **Budget 5–7 minutes per task and move on** (#8, #13); the exam has no per-question weights visible (#3), so cheap tasks are worth the same as expensive ones (**INFERRED**).
- **Easy tasks first, hard ones later** (#13, LF-forum replies in https://forum.linuxfoundation.org/discussion/856854/how-to-prepare-for-exam-lfcs-how-it-039-s-look-like).
- **Do networking/firewall tasks last** so a mistake cannot cut you off from the host mid-exam (willher's practice-exam README — https://github.com/willher/LFCS-Practice-Exam).
- **`sudo -i` immediately** on each host (#12; willher).
- **Verify before leaving a task** (#2, #13; willher: "Check your work as you go").
- **Confirm which host you are on** before typing (#4, #12; Important Instructions).
- **Use `man -k` / `apropos` / tab completion** instead of guessing (#8, #4, #10).
- **Use one killer.sh session before the exam and keep the other** in case of a retake (#4); alternatively use both attempts of the exam itself strategically (#15).

### 2.3 Synthesis — common causes of failure

1. **Running out of time** — skipped 3 tasks (#16), left 2 unattempted (#8), attempted only 15 (#18), "time management issues" (#17). Roughly 6–7 minutes per task is the whole budget (**INFERRED**).
2. **Working on the wrong host** — #4 lost two tasks this way; #12's tip 10 and the official "return to base" rule exist for this reason.
3. **Non-persistent changes** — iptables vs nftables persistence (#9); "nearly every exam task expects configurations to survive a reboot" (KodeKloud guide, https://kodekloud.com/blog/the-complete-lfcs-study-guide-for-system-administrator-certification/).
4. **Partial-credit precision** — 16/17 attempted with "2–3 partial errors" still failed (#17): every parameter in the prompt is graded (**INFERRED**).
5. **Course-vs-exam gaps** — Docker task not covered by LFS211 (#17, 2020); KodeKloud lacked labs for LDAP, timesync, proxy/LB, iptables (#9, 2025).
6. **Platform/technical problems** — 2017, 2021 and 2023 reports of hangs, resets, disconnects (#18, jeffran); 2025 reports say PSI was stable (#9, #3). Mitigation is procedural: wired network, personal laptop, single monitor, open a ticket immediately.
7. **Under-practised fundamentals** — 48% first attempt with two months of mostly video study, 75% after four days of hands-on mocks (#12).

---

## 3. Real exam task reports — recurring task types

**How to read the counts.** "Exam reports" counts *distinct candidate write-ups that say the topic appeared on, or was the thing that hurt them on, the real exam* (from §2). "Practice/mock corroboration" lists mock exams, practice repos and study guides that include the same task type (KodeKloud mock-exam forum threads reveal real mock tasks; Ghada Atef's lab scripts reveal her six Udemy practice exams' infrastructure needs). Curriculum mapping uses the official bullets in §1.2. Where a source quotes phrasing, it is reproduced; otherwise the phrasing column is an **INFERRED** paraphrase of how the task is typically remembered.

| Task type | Exam reports (n) | Practice / mock corroboration | Phrasing as remembered | Typical starting state | Gotchas | Domain |
|---|---|---|---|---|---|---|
| **Packet filtering / port redirection / NAT with iptables or nftables, made persistent** | **7** — #2 (`iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080`), #4 ("iptables ... a heavy question"), #5 ("create rules... delete them, then recreate with more parameters", persist, verify across servers), #9 (iptables vs nftables persistence), #11, #15, #3 (ufw vs firewall-cmd question in thread) | willher README ("Do networking change questions last"); KodeKloud guide; Sailor list ("firewall port opening"); LFS207 | "Redirect incoming port 80 to 8080 and make it persistent"; "Allow/deny traffic from X; ensure rules survive reboot" | Host with default (often empty) ruleset; sometimes `iptables` is the nft backend | Persist correctly per distro (`iptables-persistent`/`netfilter-persistent` on Ubuntu, `nft` + `/etc/nftables.conf`, or `firewall-cmd --permanent`); **never block 8080/4505/4506/tcp**; don't lock out your own SSH; know `-I` vs `-A`, `-t nat`, `MASQUERADE`, `DNAT`, `REDIRECT` | Networking |
| **LVM: create PV/VG/LV, extend LV and grow filesystem online** | **4** — #2 ("The most important skill is online resizing"), #4 (storage: LVM, disks, mounting), #11, #13 | KodeKloud guide ("guaranteed topic"); CertLand example ("Create a logical volume named `data-lv` of 500MB in the `storage-vg` volume group, format it with ext4, and mount it persistently at `/mnt/data`"); Ghada Atef labs (five extra 5 GB disks); Sailor list | "Extend `/dev/vg/lv` by 500 MB and grow the filesystem without unmounting"; "Create VG from /dev/sdb and /dev/sdc, LV of N GB, ext4/xfs, mount at /X persistently" | Spare unpartitioned disks attached; sometimes an LV already mounted | `lvextend -r` (or `resize2fs`/`xfs_growfs`); xfs cannot shrink; PE sizes; `pvcreate` on whole disk vs partition; forgetting `vgextend` | Storage |
| **SSL/TLS certificate work with openssl (inspect CN/expiry, generate self-signed, configure web server)** | **4** — #2 ("Use openssl to find the 'Common Name'"), #3 (`man openssl-x509`), #11, #1 | Sailor list ("web server TLS setup"); LFS207 forum note that SSL is covered thinly | "Report the CN/expiry of /path/cert.pem"; "Create a self-signed cert and serve HTTPS" | Certificate file(s) provided | `openssl x509 -in x -noout -subject -dates`; `-text`; CSR vs cert vs key; file permissions on keys | Essential Commands |
| **Containers: run docker/podman container with name, ports, volumes, memory limit, restart policy; images** | **4** — #2 (`--memory="256m"`, `--restart unless-stopped`), #13, #1, #17 (why2: Docker question not in course) | Ghada Atef exams ("deploy containers with Podman, set limits and storage"); LFS207 containers chapter | "Run image X as container Y, publish port, limit memory, restart on failure" | Engine installed; sometimes image must be pulled | podman vs docker CLI parity; rootless podman quirks; `--restart` needs the engine service enabled; volume mount syntax | Operations Deployment |
| **NFS server export and client mount (persistent)** | **3** — #2 (`ro`/`rw` export syntax), #1, #15 | Sailor list; LFS207; #2's lab advice ("Set up an NFS server on one and a client on another") | "Export /share to network N read-only; mount on client at /mnt persistently" | Server package may need installing; two hosts | `exportfs -ra`; `no_root_squash`; fstab `_netdev`; firewall on server; `showmount -e` | Storage |
| **libvirt VMs: define/start VM from qcow2 with virt-install/virsh** | **3** — #2 ("deploying a VM from an existing qcow2 disk image"), #11, #10 (practised) | KodeKloud Jan-2024 thread flagging libvirt as new; LFS207 | "Import the qcow2 at /path as VM named X with N MB RAM; make it autostart" | qcow2 image provided; libvirtd may be stopped | `virt-install --import --disk ... --os-variant`/`--osinfo`; `virsh autostart`; nested virt may be unavailable so use `--virt-type qemu` (**INFERRED**) | Operations Deployment |
| **Cron / at / systemd timers, including jobs for another user** | **2** — #2 (`crontab -u <username> -e`), #1 | Sailor list ("cron/systemd timer scheduling") | "Schedule /usr/bin/x every day at 03:00 for user bob" | User exists; crontab empty | `crontab -u`; cron field order; `/etc/cron.allow`; systemd timer needs matching `.service` and `enable --now` | Operations Deployment |
| **systemd: write a unit, enable, diagnose failing service** | **2** — #2 (`systemctl status`), #13 | KodeKloud guide; Sailor; LFS207 | "Create a service that runs /opt/app on boot"; "Service X fails to start — fix it" | Broken unit or missing file; sometimes masked | `daemon-reload`; `enable --now`; `journalctl -u`; `Restart=`; wrong `ExecStart` path; masked units | Essential Commands / Ops |
| **sshd hardening and client config (keys, Match blocks, PasswordAuthentication, port)** | **2** — #2 ("The `Match` block is your best friend"), #1 | Sailor ("SSH hardening"); KodeKloud guide | "Allow password auth only for user X; disable root login; deploy key for user Y" | Default sshd_config | `sshd -t` before restart; drop-ins in `sshd_config.d/`; `Match` must be last; don't lock yourself out | Networking |
| **Partition, format, persistent mount by UUID (fstab)** | **2** — #4, #13 | KodeKloud Mock 1 Q6 (fstab; grader initially accepted only device names, fixed Apr 2026 to accept UUID too); Sailor; Ghada Atef | "Create a 1 GB partition on /dev/sdb, ext4, mount at /data persistently" | Blank disk | `blkid`; `mount -a` to test; `x-systemd.automount`; GPT vs MBR | Storage |
| **Web server / reverse proxy / load balancer (Apache, nginx, HAProxy)** | **2** — #1 (Apache), #15 ("webservers"); #9 lists proxy/LB as a gap | LFS207; curriculum bullet | "Serve /var/www/x on port N"; "Proxy port 80 to backend :8080" | Package may need installing | SELinux booleans / `semanage port`; firewall; document root permissions | Networking |
| **Users and groups with specific UID/GID/shell/home/expiry; password ageing; sudoers** | **1** — #2; official 2018 sample-question style | Sailor ("user provisioning"); KodeKloud guide; willher practice (change a password without knowing current one) | "Create user X with UID 2000, shell /bin/sh, member of group Y, expires on DATE" | Group may not exist | `useradd -m`; `chage`; `usermod -aG`; `visudo` syntax; `/etc/skel` | Users and Groups |
| **ACLs (setfacl/getfacl)** | **1** — #11 | Bes0n notes; curriculum | "Give user X read on /dir recursively with default ACL" | Directory tree | default vs access ACL; mask; `-R`; verify with `getfacl` | Users and Groups |
| **SUID/SGID/sticky bits and permissions** | **1** — #11 | 2018 official checklist; #19 | "Set SGID on /shared so files inherit group" | Directory | numeric vs symbolic; `find -perm` to locate SUID files | Users and Groups (implicit) |
| **Resource limits (ulimit / limits.conf)** | **1** — #11 | curriculum bullet | "Limit user X to N processes / open files" | — | soft vs hard; PAM `pam_limits`; applies to new sessions only | Users and Groups |
| **Swap (partition or file with fallocate/mkswap/swapon + fstab)** | **1** — #11 | curriculum bullet | "Add 512 MB swap file persistently" | — | `fallocate` vs `dd` on some filesystems; permissions 600; `swapon --show` | Storage |
| **RAID with mdadm** | **1** — #11 (RAID 1) | Bes0n; admincool; old curriculum | "Create RAID1 from sdb and sdc, mount persistently" | Two spare disks | `mdadm --detail --scan >> /etc/mdadm/mdadm.conf` + `update-initramfs`; different config path on RHEL | Storage (not a named bullet in the current curriculum — lower priority) |
| **Network bridge / bonding** | **1** — #11 (bridge) | KodeKloud Mock 2 Q15 (add eth1 to a bridge — validator bug fixed Apr 2026); Ghada Atef labs (four NICs, `net.ifnames=0`) | "Create bridge br0 containing eth1" | Extra NIC present | netplan `bridges:` vs `nmcli con add type bridge`; STP; bond modes | Networking |
| **SELinux (mode, contexts, booleans, ports)** | **1** — #11 | curriculum bullet; Important Instructions hint about "system security policies"; #19 | "Make httpd serve from /srv/web with SELinux enforcing" | RHEL-family host | `restorecon`, `semanage fcontext/port`, `setsebool -P`; check `ausearch`/`sealert` | Operations Deployment |
| **Process management / IO monitoring (pidstat, iotop, nice, kill, signals)** | **1** — #11 ("Process IO monitoring") | KodeKloud Mock 1 Q15: find process with highest read rate and write its PID to `/opt/highread.pid` (needs `sudo pidstat -d 1`) | "Write the PID of the process reading most from disk to /opt/x" | Runaway process pre-started | run as root; `renice`; `kill -SIGTERM` vs `-9`; `ps -o` formatting | Operations Deployment / Essential Commands |
| **Shell scripting and I/O redirection** | **1** — #11 | 2018 official checklist; KodeKloud guide | "Write a script that ... and outputs to file X, errors to Y" | — | `2>&1` order; `set -e`; executable bit; shebang | Essential Commands (implicit) |
| **find with permission/size/time filters + -exec** | **1** — #1 ("Master find -exec") | tectrack (#12, one-liners); 2018 checklist | "Find files > 100 MB owned by X and move them" | — | `-size +100M`, `-perm /4000` vs `-perm -4000`, `-exec {} +` | Essential Commands (implicit) |
| **Hard and soft links** | **1** — #12 ("-s for soft links") | 2018 checklist | "Create a symlink /x pointing to /y" | — | relative vs absolute targets; hard links across filesystems impossible | Essential Commands (implicit) |
| **Archives (tar/gzip/bzip2/xz/zip)** | **1** — jeffran 2017 ("xzipping files") | 2018 checklist | "Archive /dir to /backup/x.tar.xz" | — | flag order; preserving permissions (`-p`); `--exclude` | Essential Commands (implicit) |
| **Static IP, routes, DNS/hosts with netplan / nmcli** | **1** — #13 ("network configuration and troubleshooting") | KodeKloud Mock 3 (`netplan try` after removing routes; DNS change broke `ssh node01` later); Sailor ("static IP configuration"); Ghada Atef | "Set eth1 to 10.0.0.5/24, add route to 172.16.0.0/16 via X persistently" | DHCP or unconfigured NIC | `netplan try` then `apply`; YAML indentation; `nmcli con mod ... ipv4.method manual`; `/etc/hosts` vs `resolv.conf` (systemd-resolved) | Networking |
| **Time sync (chrony/timedatectl/NTP server)** | 0 explicit (#9 lists timesync as a gap) | KodeKloud Mock 3 (install NTP server; repo access problems) | "Configure chrony to use server X; set timezone" | — | `chronyc sources`; `timedatectl set-ntp`; allow clients in `chrony.conf` | Networking |
| **Network block device (NBD) client/server** | 0 | KodeKloud Mock 3 Q17 (mount an exported NBD at `/share` on node01; leftover `/dev/nbd0` had to be detached with `nbd-client -d`) | "Attach the NBD export from server X and mount at /share" | Peer host serving nbd | `modprobe nbd`; detach stale devices; persist with systemd unit rather than fstab (**INFERRED**) | Storage |
| **LDAP client (nslcd/sssd)** | 0 (#9 lists LDAP as a gap) | KodeKloud Mock 2 Q17 (`/etc/nslcd.conf` missing; lab fixed May 2026) | "Configure the system to use LDAP server X for users" | LDAP server reachable | `nslcd` vs `sssd`; `authselect`/`pam-auth-update`; `getent passwd` to verify | Users and Groups |
| **Disk-space troubleshooting (du, find large files, full /data)** | 0 | KodeKloud Mock 1 Q16 (device 98% utilised at `/data`; lab fixed Apr 2026); admincool (`du --max-depth=1 -hx /`) | "Filesystem /data is nearly full — find and remove the cause" | Pre-filled junk files | `du -xh --max-depth=1`; deleted-but-open files (`lsof +L1`) | Essential Commands |
| **Kernel parameters (sysctl) persistent + runtime** | 0 | KodeKloud guide; curriculum bullet | "Enable ip_forward now and persistently" | — | `/etc/sysctl.d/*.conf` + `sysctl --system`; `-w` is runtime only | Operations Deployment |
| **Package management / repositories** | 0 direct (jeffran 2017: unclear whether tools must be installed) | KodeKloud guide; Important Instructions mention apt/dpkg/dnf/yum | "Install package X from repo Y; verify integrity" | Offline repos possible (**INFERRED** from Mock 3 repo failures) | `apt-cache policy`; `dnf repolist`; `rpm -V`; `dpkg -V`; GPG keys | Operations Deployment |
| **Boot targets, GRUB, rescue/recovery** | 0 | curriculum bullet ("Recover from hardware, operating system, or filesystem failures"); LFS207 rescue chapter | "Set default target to multi-user; repair filesystem X" | — | `systemctl set-default`; `fsck` only on unmounted FS; `xfs_repair` | Operations Deployment |
| **Git basics (clone, commit, branch, .gitignore)** | 1 — #1 ("Git") | curriculum bullet; LFS207 Git chapter | "Clone repo, create branch, commit file, add .gitignore" | Local repo path | `git config user.name/email` may be required before commit (**INFERRED**) | Essential Commands |
| **Automounters (autofs)** | 0 | curriculum bullet | "Automount NFS export on access" | — | direct vs indirect maps; `systemctl enable --now autofs` | Storage |
| **Storage performance monitoring (iostat, vmstat)** | 0 | curriculum bullet; Mock 1 Q15 (pidstat) | "Which device is busiest" | — | `sysstat` may need installing | Storage |
| **Quotas, PAM, kernel modules, chattr, encrypted storage (LUKS), DNS/mail servers** | 0 | Only in old-curriculum notes (StenlyTU, simonesavi, Bes0n, admincool) and Sailor's stale list | — | — | Not named in the current curriculum; keep as low-priority "awareness" material (**INFERRED**) | — |

**Multi-host discipline (cross-cutting).** Two write-ups (#4, #12) and the official instructions make "which host am I on" an explicit failure mode. The kit should print the hostname in every prompt and make tasks state the target host, exactly as the exam does (**INFERRED**).

**Task style (cross-cutting).** willher's community practice exam notes that real questions are "multi-part questions with contextual background information" and that "there is often more than one way to answer" — grading checks outcomes, not methods (**CANDIDATE-REPORTED** — https://github.com/willher/LFCS-Practice-Exam). #2 stresses that single words in the prompt (e.g. `ro` vs `rw`, "persistent") determine credit.

**Top 10 most-reported real-exam task types (by distinct exam reports):** (1) iptables/nftables filtering, redirection and persistence — 7; (2) LVM create/extend + grow FS — 4; (3) OpenSSL certificate inspection/creation — 4; (4) Containers (docker/podman with limits/restart) — 4; (5) NFS export/mount — 3; (6) libvirt VM from qcow2 — 3; (7) cron/at/timers incl. other users — 2; (8) systemd unit creation/troubleshooting — 2; (9) sshd hardening/Match/keys — 2; (10) partition/format/fstab-by-UUID mounts — 2 (tied with web server/reverse proxy — 2).

---

## 4. Practice resources

| Resource | Free / paid | What it uniquely covers | Candidate rating / evidence | Tag & URL |
|---|---|---|---|---|
| **killer.sh LFCS simulator** | Two sessions included with the exam; standalone "29.99 USD for two LFCS sessions" | 20 questions ("LFCS:20"), "the same questions in both sessions, but also more questions than in the real exams"; each question "in its own encapsulated virtual machine"; XFCE remote desktop "really close to the original one"; questions and solutions stay readable after the 36-hour window; works in Chrome/Firefox | "harder than the exam" (#3); "understatement of the century... barely finished the 23 tasks" (#9); "slightly harder than the real exam" (#10); practised "until 75/75" (#5); "use only one session before the exam" (#4). Note the 20 vs 23 task-count discrepancy between killer.sh's FAQ and #9's report | OFFICIAL/killer.sh — https://killer.sh/lfcs ; https://killer.sh/faq ; LF — https://linuxfoundation.atlassian.net/wiki/spaces/TCCS/pages/161579396 |
| **KodeKloud LFCS course + labs + mock exams** | Paid (KodeKloud subscription, or Udemy version often ~$15) | Udemy version: 11 h 42 min, 8 sections, "hands-on labs for every topic", four mock exams, Ubuntu-based, updated July 2026, 4.6★ from 2,442 ratings, 21,977 students. KodeKloud-site version: 8 modules, 103 topics, 11.25 h, 2 mock exams listed. Mock exams are graded automatically and their forum threads show realistic tasks (pidstat PID file, fstab, bridge, NBD, LDAP, netplan routes, `ssh bob@node01`) | Most-cited resource (10 write-ups); "Mock Exam is worth its weight in gold"; gaps reported: LDAP, timesync, proxy/LB, iptables labs (#9); several 2026 mock-lab bugs were reported and fixed (Mock 1 Q6/Q16, Mock 2 Q15/Q17) | CANDIDATE-REPORTED — https://www.udemy.com/course/linux-foundation-certified-systems-administrator-lfcs/ ; https://kodekloud.com/courses/linux-foundation-certified-system-administrator-lfcs ; forum: https://kodekloud.com/community/c/lfcs/23 |
| **Ghada Atef — "Ultimate LFCS Practice Exams" (Udemy) + LFCS-Lab-Scripts (GitHub)** | Udemy paid; scripts free | Six practice exams (search snippet: "Each exam includes 20 tasks, complete with step-by-step solutions"); companion repo has setup/verify/cleanup scripts for Practice Exams 1–6, cross-distribution (RHEL, AlmaLinux, Rocky, Ubuntu), idempotent, with a documented VM spec (2 vCPU, 2–4 GB RAM, 30 GB disk, **five extra 5 GB disks, four NICs eth0–eth3**, `net.ifnames=0 biosdevname=0`) | Used by #1; the Udemy page could not be fetched (403) so rating unverified; repo has 1 star / 2 forks / 28 commits | CANDIDATE-REPORTED — https://www.udemy.com/course/ultimate-lfcs-practice-exams/ ; https://github.com/Ghada-Atef/LFCS-Lab-Scripts |
| **Sander van Vugt — LFCS Complete Video Course, 3rd ed. (Pearson / O'Reilly / Coursera)** | Paid (O'Reilly subscription; Coursera specialization) | "20+ hours"; 3 Linux-Fundamentals modules + 6 LFCS modules (Advanced Sysadmin, Security, Storage, Containers & Virtualization, Essential Open Source Solutions, Practice Exam); Coursera version is 9 courses / 39 h, 4.6★ (17 reviews), Unit 9 = practice exam | Used by #2 (Coursera) and #6; O'Reilly page blocked (403) | CANDIDATE-REPORTED — https://www.sandervanvugt.com/course/linux-foundation-certified-system-administrator-complete-video-course-3/ ; https://www.coursera.org/specializations/pearson-linux-foundation-certified-system-administrator-lfcs ; https://www.oreilly.com/videos/linux-foundation-certified/9780138230678/ |
| **LFS207 — Linux System Administration Essentials (Linux Foundation)** | $299 (or $645 bundled with the exam; $625 via THRIVE-ONE) | 50–60 h, 34 chapters (filesystem tree, users, permissions, dpkg/APT/RPM/dnf/yum/zypper, Git, processes, monitoring, containers, filesystems, networking, security, systemd, backup, rescue); labs run on KVM/VMware/VirtualBox; covers Debian/Ubuntu and RHEL families. Replaced LFS201 on 14 Nov 2022 to match the new curriculum | Forum: SSL only touched in the LDAP chapter because the exam bullets were "too vague"; multiple older forum posts say the LF course alone did not prepare them for the exam (#17) | OFFICIAL — https://training.linuxfoundation.org/training/linux-system-administration-essentials-lfs207/ ; https://forum.linuxfoundation.org/discussion/862448/lfs201-vs-lfs207 |
| **sailor.sh LFCS mock-exam bundle** | Paid — $99 (listed as reduced from $250), 3 months access | 8 mock exams, 160 tasks, 20 per exam, 5 retakes each, claims to mirror the exam interface | No candidate reviews found; its own 2026 blog prints the *old* six-domain list and pre-2023 distro choice — treat with caution | CANDIDATE-REPORTED — https://sailor.sh/linux-foundation-certified-system-administrator-lfcs-certification-ready-mock-exam-bundle/ ; https://sailor.sh/blog/lfcs-exam-guide-2026/ |
| **Killercoda** | Free tier | LFCS page offers a "Single node Ubuntu Environment" playground (Linux scenarios "not specific to LFCS") and promotes a `KILLER30` 30%-off exam code | Used by #10 for hands-on practice | CANDIDATE-REPORTED — https://killercoda.com/lfcs |
| **TecMint LFCS series and eBook** | Series free; eBook paid | 33-part tutorial series "last revised on August 11, 2023" for the May-2023 curriculum; 34-chapter/375-page eBook updated Oct 2025 | Canonical older reference; no 2024–2026 candidate cites it | CANDIDATE-REPORTED — https://www.tecmint.com/sed-command-to-create-edit-and-manipulate-files-in-linux/ ; https://www.tecmint.com/lfcs-study-guide/ |
| **GitHub — giulianopz/lfcs** | Free | Notes per official bullet plus "practice questions (tasks quite similar to the real ones in the exam)"; served as an mdbook; assumes Ubuntu 18.04/20.04 | 275★ | CANDIDATE-REPORTED — https://github.com/giulianopz/lfcs ; https://giulianopz.github.io/lfcs/ |
| **GitHub — willher/LFCS-Practice-Exam** | Free | 26-question two-hour practice exam with step-by-step answers; `setup.sh` builds the environment on CentOS Stream 8 (interactive, run as root, installs packages and pulls an nginx image); README tips (be root, networking last, verify as you go) | 19★ / 14 forks | CANDIDATE-REPORTED — https://github.com/willher/LFCS-Practice-Exam |
| **GitHub — elliotholden/lfcs-practice-exam** | Free | Vagrant + VirtualBox + Ansible lab: three CentOS 7 VMs (home 1.2.3.4, server1 1.2.3.5, server2 1.2.3.6) with lsof/tree/bind-utils/traceroute pre-installed, plus a practice-question PDF | Dated (CentOS 7) but a good pattern for a multi-VM lab | CANDIDATE-REPORTED — https://github.com/elliotholden/lfcs-practice-exam |
| **GitHub — maxbischoff/lfcs-practice** | Free (archived 25 Feb 2024) | Domain-organised practice questions run in Docker (Dockerfile/Makefile/sudoers) | 11★ | CANDIDATE-REPORTED — https://github.com/maxbischoff/lfcs-practice |
| **GitHub — ahsfar/LFCS-guide** | Free | Notes organised by the *current* five domains, from KodeKloud course + web; `practice`, `scripts`, `tips` folders | 14★ / 188 commits | CANDIDATE-REPORTED — https://github.com/ahsfar/LFCS-guide |
| **GitHub — Bes0n/LFCS** | Free | Multi-distro (CentOS, Ubuntu, SUSE) notes with lab exercises and solutions incl. RAID, quotas, DNS/NFS/CIFS, virtualisation | 52★ | CANDIDATE-REPORTED — https://github.com/Bes0n/LFCS |
| **GitHub — StenlyTU/LFCS-official, simonesavi/lfcs, xezpeleta/lfcs, karakays/lfcs, cloudchristina/lfcs, WairimuMaringa/LFCS, 5fff/lfcs** | Free | Old-curriculum (six-domain, CentOS-centric) notes; StenlyTU includes what it calls "the official practice questions" and a 66% pass mark; simonesavi is the most starred (382★) | Useful for fundamentals; do not use for weighting | CANDIDATE-REPORTED — https://github.com/StenlyTU/LFCS-official ; https://github.com/simonesavi/lfcs ; https://github.com/xezpeleta/lfcs ; https://github.com/karakays/lfcs ; https://github.com/cloudchristina/lfcs ; https://github.com/WairimuMaringa/LFCS ; https://github.com/5fff/lfcs |
| **Pluralsight (Andrew Mallett) LFCS content** | Paid | Intro course last updated 27 Feb 2023 on Ubuntu 20.04 | Dated; StenlyTU's notes derive from Mallett's older course | CANDIDATE-REPORTED — https://www.pluralsight.com/courses/linux-foundation-certified-system-administrator-intro-cert |
| **A Cloud Guru** | Paid | Used as a secondary review by #3 | — | CANDIDATE-REPORTED — see #3 |
| **LFS101 (free)** and the 2018 LF Certification Preparation Guide | Free | LF's suggested on-ramp; the 2018 guide is historical only | OFFICIAL — https://resources.linuxfoundation.org/LF+Training/LF_Training_WP_CertificationPrepGuide_October2018+(6).pdf |
| **Books** | Paid | Linux Bible (Negus); UNIX & Linux System Administration Handbook 5e | #1, #6 | CANDIDATE-REPORTED |
| **Dump sites** (validexamdumps, certbolt, passitexams, exambible, marks4sure, "LFCS Questions 2026" on LeetCode Discuss, P2PExams, Pass4sure) | Paid | MCQ-style "questions" for a hands-on exam; some cited by two forum posters | Not representative; sharing real exam content breaches the LF Certification and Confidentiality Agreement | Excluded — https://docs.linuxfoundation.org/tc-docs/certification/lf-cert-agreement |

**No official LF practice-question document for the current curriculum was found.** The "official practice questions" referenced by StenlyTU and Arun Pal belong to the pre-2023 exam.

---

## 5. Exam-day technique (synthesised from §1–§3)

**Man pages and discovery (no internet)**
- `man -k keyword` / `apropos keyword` to find the command; then `man cmd` and `/pattern` to search (#8, #4). Read "SEE ALSO" (#10). `cmd --help | less` and `grep` inside help output (#3). Tab-completion to discover command names (#10). `grep -r pattern /etc` to find config files (#10). Config examples often live in `/usr/share/doc/<pkg>/examples` — explicitly allowed (OFFICIAL, §1.5).
- Vim: INSERT key is disabled — use `i`; practise `:set paste`, `:wq`, search/replace (OFFICIAL, §1.6; #4, #5).

**Shell hygiene**
- `sudo -i` first on each host (OFFICIAL; #12; willher). Set a visible prompt (`PS1='\u@\h:\w\$ '`) so the hostname is always visible (**INFERRED** from #4/#12). Ctrl+R history search (#13). Aliases are optional — the simulator/exam shell is bash on a fresh host each task, so don't rely on customisation (**INFERRED**, since each task is a separate VM per killer.sh).
- Copy/paste inside the terminal is Ctrl+Shift+C/V; Ctrl+W closes the browser tab — use Ctrl+Alt+W (OFFICIAL).

**Verification checklist per task (INFERRED from the reports and the task table)**
- Storage: `lsblk -f`, `blkid`, `mount | grep`, `df -h`, `findmnt --verify`, `mount -a` after editing fstab, `swapon --show`, `lvs`/`vgs`/`pvs`.
- Users: `id user`, `getent passwd user`, `chage -l user`, `getfacl path`, `stat -c %A path`, `sudo -l -U user`.
- Services: `systemctl is-enabled --now` equivalents (`is-active`, `is-enabled`), `journalctl -u svc -b`, `ss -tulpn` for listening ports.
- Network: `ip -br a`, `ip r`, `resolvectl status`/`cat /etc/resolv.conf`, `getent hosts name`, `ping`/`curl` the target, `iptables -S`/`nft list ruleset`, `firewall-cmd --list-all`, then confirm the persistence file exists.
- Security: `getenforce`, `ls -Z`, `sestatus`, `ausearch -m avc -ts recent`.
- Re-read the task before `exit`; check the host prompt; leave with `exit` (never nested `ssh`) (OFFICIAL; #4; #12).

**Time and ordering**
- 17–20 tasks in 120 minutes → ~6 minutes each; cap any task at 5–7 minutes, mark it, come back (#8, #13).
- Do quick, self-contained tasks (users, permissions, cron, git) first; leave firewall/network/reboot-sensitive tasks for the end (willher; #13).
- Don't attempt to reboot `base`; reboot other nodes only if a task demands it (OFFICIAL).

**Common mistakes and recovery**
- *Wrong host* — #4 lost two tasks; recovery: redo on the correct host and undo on the wrong one if it could interfere (**INFERRED**).
- *Non-persistent change* — iptables rules not saved, sysctl `-w` only, `mount` without fstab, `enable` forgotten (#9; KodeKloud guide). Recovery: after finishing each task, ask "would this survive a reboot?" and add the file-based configuration.
- *Locking yourself out* — a firewall or sshd change that drops SSH. Prevention: on the exam **never block 8080/4505/4506** (OFFICIAL); test sshd with `sshd -t`; add rules with an explicit `ACCEPT` for 22 before any default-DROP policy; on Ubuntu use `netplan try` (auto-reverts) (**INFERRED** from KodeKloud Mock 3). If a node becomes unreachable, the official instructions allow rebooting any node other than `base` (search snippet of the Important Instructions page; the current page states only that `base` must not be rebooted) — but a reboot only helps if the bad rule was not persisted.
- *Editing the wrong file* — e.g. `/etc/ssh/ssh_config` vs `sshd_config`, `/etc/default/grub` vs `grub.cfg`, `fstab` typos: use `mount -a`, `sshd -t`, `visudo -c`, `netplan try` as validators (**INFERRED**).
- *Platform trouble* — frozen terminal/disconnect: the timer does not stop and no time is added back (OFFICIAL, ExamUI page); tell the proctor via chat immediately and open a ticket at trainingsupport.linuxfoundation.org afterwards (OFFICIAL — https://forum.linuxfoundation.org/discussion/870759/terminal-froze-and-session-disconnected-could-not-rejoin-properly-forced-to-end-exam). Use a personal laptop, wired network, single monitor (OFFICIAL, §1.6).
- *Ambiguous prompts* — if a task assumes a tool that is not installed, installing distribution packages is allowed (OFFICIAL, §1.5); jeffran's 2017 complaint shows this ambiguity is old.

---

## 6. Lab requirements for practice (Apple Silicon Mac)

### 6.1 Hypervisor options

| Tool | Ubuntu 24.04 | Rocky 9 / CentOS Stream 9 | Extra virtual disks for LVM/partitioning | Multiple NICs (bridge/bond practice) | Notes | Tag & source |
|---|---|---|---|---|---|---|
| **Lima** (`limactl`) | `limactl start template:ubuntu-24.04` (also `ubuntu-26.04` default) | `template:rocky-9`, `almalinux-9`, `centos-stream-9`, `centos-stream-10` | **Yes**: `limactl disk create data --size 20GiB` then `additionalDisks:` in the instance YAML or `limactl edit <inst> --set '.additionalDisks += [{"name":"data"}]'` (instance must be stopped); `format: true`/`fsType` optional; disks survive instance deletion | Limited — Lima exposes one user-mode NIC by default; extra networks need `vmnet`/socket_vmnet configuration (**INFERRED**) | Uses Apple's `vz` hypervisor by default since Lima 1.0; arm64 native | OFFICIAL docs — https://lima-vm.io/docs/templates/ ; https://lima-vm.io/docs/config/disk/ ; https://lima-vm.io/docs/reference/limactl_disk_create/ |
| **Multipass** | Yes (Ubuntu only) | No | **No** — "we do not currently support adding multiple disks to an instance" (Canonical, 2023–2024); feature request #135 open since 2018; only the root disk can be **grown** (`multipass set local.<name>.disk=<size>`) | Limited | Fine for single-host Ubuntu tasks; for LVM practice use loop devices (`fallocate -l 2G /var/tmp/d1.img; losetup -fP --show /var/tmp/d1.img`) as stand-ins — works for pvcreate/mkfs/fstab but not for realistic device names (**INFERRED**) | OFFICIAL docs — https://canonical.com/multipass/docs//latest/how-to-guides/manage-instances/modify-an-instance/ ; https://discourse.ubuntu.com/t/multipass-and-multiple-disks/35677 ; https://github.com/canonical/multipass/issues/135 |
| **UTM** (QEMU/Apple Virtualization GUI) | Yes (arm64 ISO) | Yes (aarch64 ISO or GenericCloud qcow2) | **Yes**: Drives → "New…", choose size (MB/GB), VirtIO by default, optional NVMe interface "if you encounter disk I/O problems with certain Linux distributions", optional "Removable" external image; raw images only for import | Yes — multiple network adapters can be added per VM (shared/bridged/host-only/emulated) | Best GUI option for multi-disk + multi-NIC labs; snapshots via QEMU backend | OFFICIAL docs — https://docs.getutm.app/settings-apple/drive/ ; https://docs.getutm.app/basics/basics/ |
| **VirtualBox 7.1+** | arm64 guests only | arm64 guests only | Yes (standard VirtualBox storage controllers) | Yes (up to 8 adapters, host-only networks) | 7.1 "introduces initial support for macOS on Apple silicon" — Arm guests only, "cannot run any x86 or x86_64 guest"; 7.2 adds macOS/Windows-on-Arm guests. Ghada Atef's scripts target VirtualBox/VMware | OFFICIAL — https://blogs.oracle.com/virtualization/oracle-virtualbox-710 ; https://blogs.oracle.com/virtualization/oracle-virtualbox-72 |
| **Vagrant** | via `vagrant-qemu` plugin (recommended on Apple Silicon, April 2025 review), Parallels provider (Pro edition), or VirtualBox 7.1 | arm64 boxes exist but a Rocky 9 box "fails on Apple Silicon – architecture mismatch despite ARM64 listing" (hashicorp/vagrant #13588) | Provider-dependent; VirtualBox provider supports extra disks via `config.vm.disk` / `VBoxManage` | Provider-dependent | Good for reproducible two-VM labs once a working box is found; elliotholden's repo is the pattern | CANDIDATE-REPORTED — https://dev.to/rajinh24/vagrant-on-apple-silicon-m4-kvm-vs-qemu-vs-libvirt-what-works-best-7n8 ; https://github.com/hashicorp/vagrant/issues/13588 ; https://github.com/elliotholden/lfcs-practice-exam |

**Images.** Rocky Linux publishes aarch64 GenericCloud qcow2 images (currently `Rocky-9-GenericCloud-Base-9.8-20260525.0.aarch64.qcow2` and an LVM variant) that boot directly in UTM/Lima with cloud-init. **OFFICIAL** — https://dl.rockylinux.org/pub/rocky/9/images/aarch64/ . Ubuntu's ARM server download page now lists 26.04.1 LTS; 24.04 LTS arm64 ISOs remain under "Alternative and previous releases" at cdimage.ubuntu.com/releases. **OFFICIAL** — https://ubuntu.com/download/server/arm

**Architecture caveat (INFERRED).** The exam almost certainly runs x86_64 VMs; on Apple Silicon your guests are arm64. Everything in the curriculum behaves identically except: GRUB/boot details (UEFI only on arm64 VMs), a few kernel-module names, and package availability of some x86-only tools. If bootloader/rescue practice matters, UTM can also emulate x86_64 (slowly) via QEMU.

### 6.2 Recommended lab topology (INFERRED from the official environment and candidate labs)

- **`base`** — your Mac terminal, or a tiny Ubuntu VM with only ssh (mirrors the real `base` that has no editors).
- **`node1` — Ubuntu 24.04 LTS** (primary; netplan, ufw/iptables/nftables, apt, AppArmor): 2 vCPU, 2–4 GB RAM, 20–30 GB root disk, **plus 3–5 blank 2–5 GB disks** (Ghada Atef's spec is five 5 GB disks) for partitioning, LVM, RAID and swap tasks, and **2–4 NICs** for bridge/bond/static-route tasks (Ghada Atef uses four NICs with `net.ifnames=0 biosdevname=0`).
- **`node2` — Rocky 9 (or CentOS Stream 9)** (dnf, firewalld, NetworkManager/nmcli, SELinux enforcing): same shape.
- Password-less SSH from `base` to both nodes; `/etc/hosts` entries so `ssh node1` works exactly like the exam; snapshots after provisioning so every practice run starts clean (Ghada Atef's "snapshot-based workflow").
- **Two-host scenarios** to script: NFS server on node2 → client on node1 (and reverse); NBD export/import (KodeKloud Mock 3); static route between the two private networks; chrony server on one, client on the other; HAProxy/nginx on node1 proxying to httpd on node2; LDAP client (needs a small OpenLDAP or 389-ds container on node2 — **INFERRED**).

### 6.3 Cloud alternatives

- **KodeKloud hosted labs** — "no local hardware needed"; #9 prepared entirely there. **CANDIDATE-REPORTED** — https://engineering.cloudeteer.de/blog/2025/passing-the-linux-foundation-certified-systemsadministrator-certification-in-2.5-days/
- **Killercoda Ubuntu playground** — free single-node Ubuntu for quick drills. **CANDIDATE-REPORTED** — https://killercoda.com/lfcs
- **AWS Free Tier** (new model): "up to $200 in credits" over 6 months, account auto-closes when credits run out — enough for x86_64 practice VMs with extra EBS volumes for LVM (**INFERRED** for suitability). **OFFICIAL** — https://aws.amazon.com/free/
- **Hetzner Cloud** — cheap x86 and Arm (CAX) servers with attachable volumes; prices not extracted (page renders dynamically). **OFFICIAL** — https://www.hetzner.com/cloud/
- Candidate #6 recommends any cloud but warns to decommission resources afterwards. **CANDIDATE-REPORTED** — https://okpallannaemeka.medium.com/a-short-guide-to-acing-the-linux-foundation-certified-system-administrator-lfcs-exam-2db4518931e6

### 6.4 Scripts and repos that automate an LFCS lab

| Repo | What it automates | Distro | Status |
|---|---|---|---|
| Ghada-Atef/LFCS-Lab-Scripts — https://github.com/Ghada-Atef/LFCS-Lab-Scripts | Setup, verification and cleanup for six practice exams; device-safety checks; idempotent; NetworkManager vs netplan handled | RHEL/Alma/Rocky/Ubuntu | Active (2025–2026); 28 commits |
| willher/LFCS-Practice-Exam — https://github.com/willher/LFCS-Practice-Exam | `setup.sh` prepares a 26-question exam environment | CentOS Stream 8 | 40 commits; distro dated |
| elliotholden/lfcs-practice-exam — https://github.com/elliotholden/lfcs-practice-exam | Vagrant + Ansible three-VM lab | CentOS 7 | Dated pattern |
| maxbischoff/lfcs-practice — https://github.com/maxbischoff/lfcs-practice | Docker-based question environments | — | Archived Feb 2024 |
| LFS207 course labs — https://training.linuxfoundation.org/training/linux-system-administration-essentials-lfs207/ | Official lab setup instructions for KVM/VMware/VirtualBox | Debian & RHEL families | Current |

**INFERRED design note for the kit's practice CLI.** The strongest existing pattern (Ghada Atef, willher, and this repo's own CKA CLI) is `setup.sh` / `verify.sh` / `cleanup.sh` per task, run as root inside the VM, with verification mirroring the exam's outcome-based grading (check files, `systemctl is-enabled`, `findmnt`, `getent`, `nft list ruleset`, etc.). Two distro flavours (Ubuntu 24.04 primary, Rocky 9 secondary) and a "which host" element per task would mirror the real exam most closely.

---

## 7. Implications for the preparation kit (INFERRED)

1. **Weight the task bank by the official domains** (25/25/20/20/10) but **over-index practice on the seven most-reported real-exam themes**: iptables/nftables persistence, LVM online growth, OpenSSL inspection, containers with limits/restart, NFS, libvirt from qcow2, and multi-host discipline.
2. **Build every task to require persistence** and grade it the way LF does — by outcome, after a simulated reboot where feasible.
3. **Ship two flavours per networking/firewall/security task** (netplan+ufw/iptables/AppArmor vs nmcli+firewalld+SELinux), because the official position is "distribution-independent" and the curriculum explicitly names SELinux.
4. **Timebox mock exams at 17–20 tasks / 120 minutes**, print the target host in every task, and forbid nested SSH in the harness.
5. **Study plan:** an experienced CKA/CKAD holder reports 2 days (#11), 2.5 days / 25 h (#9), 15 days (#10) or ~2 weeks of final drilling (#3); newer-to-Linux candidates report 2–6 months (#6, #12, #8). The voucher (expires March 2027) leaves room for a 4–6-week plan with one killer.sh session ~1 week before the exam and the second held for a possible retake (#4).

---

## Appendix A — All sources consulted (grouped)

**Official (Linux Foundation / CNCF / killer.sh)**
- https://training.linuxfoundation.org/certification/linux-foundation-certified-sysadmin-lfcs/
- https://docs.linuxfoundation.org/tc-docs/certification/instructions-lfcs-and-lfce (and `.md` raw version)
- https://training.linuxfoundation.org/blog/updated-linux-foundation-certified-system-administrator-lfcs-exam/
- https://training.linuxfoundation.org/blog/exam-simulators/
- https://linuxfoundation.atlassian.net/wiki/spaces/TCCS/pages/161579396/How+do+I+access+the+exam+simulator+Practice+Exams
- https://training.linuxfoundation.org/about/policies-2-2026/certification-exam-retake-policy/
- https://training.linuxfoundation.org/about/faqs/certification-faq/
- https://training.linuxfoundation.org/certification-policy-change-2024/
- https://training.linuxfoundation.org/blog/new-certification-pricing/
- https://docs.linuxfoundation.org/tc-docs/certification/lf-handbook2
- https://docs.linuxfoundation.org/tc-docs/certification/lf-handbook2/certificates-and-certification
- https://docs.linuxfoundation.org/tc-docs/certification/lf-handbook2/exam-scoring-and-notification/exam-results-no-pass
- https://docs.linuxfoundation.org/tc-docs/certification/lf-handbook2/exam-rules-and-policies
- https://docs.linuxfoundation.org/tc-docs/certification/lf-handbook2/exam-user-interface/examui-performance-based-exams
- https://docs.linuxfoundation.org/tc-docs/certification/lf-cert-agreement
- https://training.linuxfoundation.org/training/linux-system-administration-essentials-lfs207/
- https://training.linuxfoundation.org/certification/golden-kubestronaut-bundle/
- https://training.linuxfoundation.org/resources/kubestronaut-program/
- https://www.cncf.io/training/kubestronaut/kubestronaut-faq/
- https://training.linuxfoundation.org/blog/meet-luis-felipe-hernandez/
- https://resources.linuxfoundation.org/LF+Training/LF_Training_WP_CertificationPrepGuide_October2018+(6).pdf
- https://forum.linuxfoundation.org/discussion/862448/lfs201-vs-lfs207 ; https://forum.linuxfoundation.org/discussion/869018/on-which-os-did-you-take-your-lfcs-exam ; https://forum.linuxfoundation.org/discussion/870759/terminal-froze-and-session-disconnected-could-not-rejoin-properly-forced-to-end-exam (LF staff replies)
- https://killer.sh/lfcs ; https://killer.sh/faq

**Candidate / community**
- Medium: pierretenrique; eodenyire; wattsdave; rafaelmedeiros94; christinacc; okpallannaemeka; jenksgibbons; kienlt.qn; willemberroubache; alonso.parasxidis (URLs in §2)
- dev.to/arunpal_ ; engineering.cloudeteer.de ; developer.mamezou-tech.com ; tectrack.net ; qainsights.com
- LF Forums: 868280, 860093, 474345, 859058, 855771, 856715, 856854, 859343
- KodeKloud community: 405357, 468650, 241305, 464199, 492749, 497175, 500701, 498138, 497200, 497304, 497201, 497378 ; category https://kodekloud.com/community/c/lfcs/23
- KodeKloud blog, course and Udemy pages; KodeKloud Golden Kubestronaut path; YouTube Nn83r7PrYZI
- GitHub: giulianopz, willher, maxbischoff, elliotholden, StenlyTU, ahsfar, karakays, Bes0n, xezpeleta, cloudchristina, simonesavi, WairimuMaringa, 5fff, Ghada-Atef, kodekloudhub/community-faq, killer-sh org
- sailor.sh, certland.net, adamdjellouli.com, admincool.com, tecmint.com, sandervanvugt.com, coursera.org, pluralsight.com, golden-kubestronaut-learning.readthedocs.io

**Lab tooling**
- https://lima-vm.io/docs/templates/ ; https://lima-vm.io/docs/config/disk/ ; https://lima-vm.io/docs/reference/limactl_disk_create/
- https://canonical.com/multipass/docs//latest/how-to-guides/manage-instances/modify-an-instance/ ; https://discourse.ubuntu.com/t/multipass-and-multiple-disks/35677 ; https://github.com/canonical/multipass/issues/135
- https://docs.getutm.app/settings-apple/drive/ ; https://docs.getutm.app/basics/basics/
- https://blogs.oracle.com/virtualization/oracle-virtualbox-710 ; https://blogs.oracle.com/virtualization/oracle-virtualbox-72
- https://dev.to/rajinh24/vagrant-on-apple-silicon-m4-kvm-vs-qemu-vs-libvirt-what-works-best-7n8 ; https://github.com/hashicorp/vagrant/issues/13588
- https://dl.rockylinux.org/pub/rocky/9/images/aarch64/ ; https://ubuntu.com/download/server/arm
- https://aws.amazon.com/free/ ; https://www.hetzner.com/cloud/
