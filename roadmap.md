# Certification Roadmap — September 2026 to March 2027

Two exams, two vouchers, one deadline. CKS first while Kubernetes is fresh from CKA and CKAD, LFCS second, and a retake buffer before both vouchers expire.

<!-- toc -->
## Table of Contents

- [The deadline](#the-deadline)
  - [Booking is the blocking task](#booking-is-the-blocking-task)
  - [Retake arithmetic against 3 March](#retake-arithmetic-against-3-march)
- [The shape of it](#the-shape-of-it)
- [Booking and activation checklist](#booking-and-activation-checklist)
- [Why this order](#why-this-order)
- [If something slips](#if-something-slips)
- [The plans](#the-plans)

<!-- toc stop -->

## The deadline

**Both vouchers expire on Wednesday 3 March 2027.** Everything, including a retake, must be sat before that date.

| | |
|---|---|
| CKS voucher expiry | **3 March 2027** |
| LFCS voucher expiry | **3 March 2027** |
| CKS exam | Target Saturday 12 December 2026 — **not yet booked** |
| LFCS exam | Target Saturday 6 February 2027 — **not yet booked** |

### Booking is the blocking task

Neither exam is scheduled, and that blocks more than the exam date. Booking is what releases the two killer.sh simulator sessions, and both study calendars schedule those sessions on specific days: 28 November and 9 December for CKS, 23 January and 3 February for LFCS. Until the exams are booked, those days have nothing to put in them.

Book both now, in one sitting. The dates can be moved later; the simulator access cannot be obtained any other way.

### Retake arithmetic against 3 March

The retake is included with each voucher and, on the evidence, is worth planning for rather than hoping to avoid: eight of the 28 CKS candidate write-ups behind this kit failed a first attempt, and every one of them passed the retake.

| Attempt | Planned date | Days to expiry | Retake Saturdays still available |
|---|---|---|---|
| CKS | Sat 12 Dec 2026 | 81 | 11 (19 Dec through 27 Feb) |
| LFCS | Sat 6 Feb 2027 | 25 | 3 (13, 20 and 27 Feb) |

The last usable Saturday before expiry is **27 February 2027**.

**The one hard backstop:** if LFCS slips, sit it no later than **Saturday 13 February 2027**. That still leaves two retake Saturdays. Past that date a single bad result costs the certification, because there is no room for a second attempt.

CKS has no such pressure. Even a December failure leaves eleven Saturdays, so a CKS retake can be taken in January without touching the LFCS plan.

## The shape of it

| Month | CKS | LFCS |
|---|---|---|
| Sep 2026 | Book the exam. Build both lab tiers. Study starts Sat 26 Sep. | |
| Oct 2026 | Foundation: one domain per weekend | |
| Nov 2026 | Foundation closes 8 Nov. Drills 9 to 29 Nov. Repo mocks 14 and 21 Nov. killer.sh session 1 on 28 Nov. | |
| Dec 2026 | Repo mock 3 on 5 Dec. killer.sh session 2 on 9 Dec. **Exam Sat 12 Dec.** | Lab build Sun 13 Dec. Foundation starts. |
| Jan 2027 | Retake window if needed | Foundation to 10 Jan, drills to 31 Jan. Repo mocks 10, 16, 31 Jan. killer.sh session 1 on 23 Jan. |
| Feb 2027 | | killer.sh session 2 on 3 Feb. **Exam Sat 6 Feb.** Retake window follows. |
| Mar 2027 | Vouchers expire | Vouchers expire |

## Booking and activation checklist

- [ ] **Book CKS for Sat 12 Dec 2026.** Not yet done. Booking releases the two killer.sh sessions.
- [ ] Confirm the portal shows an **Exam Simulator** button for CKS. Some voucher schemes exclude killer.sh.
- [ ] **Book LFCS for Sat 6 Feb 2027.** Not yet done. Sit it no later than Sat 13 Feb to keep two retake Saturdays before the 3 March expiry.
- [ ] Activate CKS killer.sh session 1 on 28 Nov and session 2 on 9 Dec. Each gives 36 hours of access from activation, so do not activate early.
- [ ] Activate LFCS killer.sh session 1 on 23 Jan and session 2 on 3 Feb.
- [ ] Keep a KodeKloud subscription active from late September to early February.

## Why this order

CKS builds directly on CKA and CKAD, so the Kubernetes fluency is already there and only the security tooling is new. LFCS shares almost nothing with it and needs its own lab, so it slots in cleanly afterwards. Passing CKS on or after 18 June 2026 also extends the CKA certification under the CARE policy, which protects the Kubestronaut track while LFCS is in progress.

The two exams also fail for different reasons. CKS punishes slow work on node-level tasks. LFCS punishes changes that do not survive a reboot and work done on the wrong host. The two study plans drill those two habits specifically.

## If something slips

Each voucher includes one free retake, and both vouchers die on 3 March 2027, so the retake must be sat before that date too.

- A CKS failure on 12 Dec leaves eleven Saturdays for the retake. Take it in January, before LFCS drills peak.
- An LFCS failure on 6 Feb leaves three Saturdays: 13, 20 and 27 February.
- **If LFCS slips, 13 February is the last date that still leaves two retake Saturdays.** Beyond it, one bad result ends the attempt.
- If CKS slips into January, do not let LFCS slip with it. Compress the LFCS drill weeks instead, because the LFCS deadline is the binding one.

## The plans

- CKS: [`cks/study-plan/00-calendar.md`](cks/study-plan/00-calendar.md) and [`cks/study-plan/README.md`](cks/study-plan/README.md)
- LFCS: `lfcs/study-plan/00-calendar.md` (built in December, before study starts)
- Evidence behind both: [`docs/research/`](docs/research/)
- Design and build plans: [`docs/superpowers/`](docs/superpowers/)
