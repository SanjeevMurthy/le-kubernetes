# Certification Roadmap — September 2026 to March 2027

Two exams, two vouchers, one deadline. CKS first while Kubernetes is fresh from CKA and CKAD, LFCS second, and a retake buffer before both vouchers expire.

<!-- toc -->
## Table of Contents

- [Fill these in first](#fill-these-in-first)
- [The shape of it](#the-shape-of-it)
- [Booking and activation checklist](#booking-and-activation-checklist)
- [Why this order](#why-this-order)
- [Retake arithmetic](#retake-arithmetic)
- [The plans](#the-plans)

<!-- toc stop -->

## Fill these in first

| Item | Value |
|---|---|
| CKS voucher expiry | _confirm in the training portal_ |
| LFCS voucher expiry | _confirm in the training portal_ |
| CKS exam booked for | Saturday 12 December 2026 |
| LFCS exam booked for | Saturday 6 February 2027 |

Both vouchers were purchased with an expiry in March 2027. The exact dates decide how much retake room the plan really has, so confirm them before booking.

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

- [ ] Book CKS for 12 Dec 2026. Booking releases the two killer.sh sessions.
- [ ] Confirm the portal shows an **Exam Simulator** button for CKS. Some voucher schemes exclude killer.sh.
- [ ] Book LFCS for 6 Feb 2027 and confirm its simulator access too.
- [ ] Activate CKS killer.sh session 1 on 28 Nov and session 2 on 9 Dec. Each gives 36 hours of access from activation, so do not activate early.
- [ ] Activate LFCS killer.sh session 1 on 23 Jan and session 2 on 3 Feb.
- [ ] Keep a KodeKloud subscription active from late September to early February.

## Why this order

CKS builds directly on CKA and CKAD, so the Kubernetes fluency is already there and only the security tooling is new. LFCS shares almost nothing with it and needs its own lab, so it slots in cleanly afterwards. Passing CKS on or after 18 June 2026 also extends the CKA certification under the CARE policy, which protects the Kubestronaut track while LFCS is in progress.

The two exams also fail for different reasons. CKS punishes slow work on node-level tasks. LFCS punishes changes that do not survive a reboot and work done on the wrong host. The two study plans drill those two habits specifically.

## Retake arithmetic

Each voucher includes one free retake, valid within 12 months of the original purchase. Candidate reports show first-attempt failures are common and retakes almost always pass, so the plan treats the retake as expected insurance rather than a fallback.

- A CKS failure on 12 Dec leaves January free for the retake, before LFCS study peaks.
- An LFCS failure on 6 Feb leaves roughly four weeks before the March expiry.
- If CKS slips past mid-January, shift the LFCS calendar by the same amount and re-check that the LFCS retake still fits before expiry.

## The plans

- CKS: [`cks/study-plan/00-calendar.md`](cks/study-plan/00-calendar.md) and [`cks/study-plan/README.md`](cks/study-plan/README.md)
- LFCS: `lfcs/study-plan/00-calendar.md` (built in December, before study starts)
- Evidence behind both: [`docs/research/`](docs/research/)
- Design and build plans: [`docs/superpowers/`](docs/superpowers/)
