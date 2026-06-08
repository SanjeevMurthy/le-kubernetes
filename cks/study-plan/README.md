# CKS Study Plan

A realistic, evidence-based plan to go from **CKA-certified** (✅ done) to **CKS-certified**, tuned for someone **new to the security tooling** (AppArmor, seccomp, Falco, Trivy, OPA/Kyverno, audit logs, gVisor).

## Your parameters

| | |
|--|--|
| CKA | ✅ Passed (prerequisite met — you can register now) |
| Security-tooling level | Beginner → System Hardening + Runtime Security are front-loaded and over-weighted |
| Time budget | **Days 1–15: 2 h/day** (30 h) · **Days 16–45: 1 h/day** (30 h) = **~60 h over ~45 days** |
| Anchor course | KodeKloud — *CKS by Mumshad Mannambeth* (theory + in-browser labs) |
| Daily reps | killercoda *killer-shell-cks* (free, timed) |
| Final exam sim | killer.sh (2 free sessions with your exam voucher) — harder than the real exam by design |
| Target | Flexible date → **book the exam for ~Day 45 now** to create productive deadline pressure |

> **First action:** register for the CKS exam (gets you the 2 free killer.sh sessions) and book a date ~45 days out. Every passing candidate who delayed regretted it; a firm date is the single biggest motivation lever.

## The three phases

| Phase | Days | Pace | Goal |
|-------|------|------|------|
| **1 — Foundation** | 1–15 | 2 h/day | Cover all 6 domains once, hands-on. Build muscle memory + Anki deck. Front-load System Hardening & Runtime Security. |
| **2 — Consolidation** | 16–35 | 1 h/day | Interleaved **timed** drills, closed-book GitHub exercises, weekly mixed mocks, weekend deep-cluster tasks. Spaced re-review of every domain. |
| **3 — Simulation & polish** | 36–45 | 1 h/day | Both killer.sh sessions, weak-area drills, docs-navigation speed, exam-day rehearsal. |

Full day-by-day breakdown: [`00-daily-schedule.md`](00-daily-schedule.md).

## The 6 study principles this plan is built on

Each is wired into the daily schedule — these are *why* the days look the way they do.

1. **Active recall over re-reading.** After every lesson, close the docs and *type the solution from memory* on a cluster. Re-reading feels productive and isn't. (Karpicke & Roediger 2008)
2. **Spaced repetition.** Review each topic at +1, +3, +7, +14 days. A 15-min Anki review opens every single day (apiserver flags, file paths, RBAC verbs, Falco fields, PSA labels). (Spacing effect / Ebbinghaus)
3. **Interleaving, not blocking.** In Phase 2, never do two consecutive tasks from the same subdomain — it forces the discrimination the exam demands (AppArmor vs seccomp vs gVisor). (Kornell & Bjork 2008)
4. **Generation effect — type it, don't paste it.** For the first two weeks, hand-type every command and YAML snippet. Motor + semantic memory encode together. Copy-paste only to verify a working answer.
5. **Deliberate practice with timed feedback.** Every killercoda scenario is run against a stopwatch — target **≤ 8 min/task** (real exam ≈ 6–8 min/task). Anything slower goes on your **drill list** for the next session.
6. **Maintain momentum.** CKS leans on short-term procedural memory (exact paths, exact flags). Do **not** take multi-day breaks; a short daily touch beats sporadic long sessions.

## Daily ritual (use this template every day)

```
[ 0:00 ] 15 min — Anki review (yesterday's cards + due cards), random order
[ 0:15 ] main block — KodeKloud lesson + hands-on (Phase 1) OR timed killercoda/exercises (Phase 2/3)
[ -0:15 ] last 15 min — close everything, write from memory: "what did I learn, what are the exact commands?"
                        → turn each gap into 2–3 new Anki cards
```

**Non-negotiables baked into the plan (from real exam debriefs):**
- Don't skip **Falco** — it's on nearly every exam and is the #1 "I skipped it and failed" topic.
- Don't skip **Linux fundamentals** — node hardening (systemctl, users, modules, ports) trips up Kubernetes-only candidates.
- **Verify every task** — 60-second sanity check after each one (`auth can-i`, `aa-status`, pod Running, crictl inspect).
- Practice **speed, not just correctness** — failing candidates almost always *ran out of time*, they didn't lack knowledge.

## How to use these files

- [`00-daily-schedule.md`](00-daily-schedule.md) — open this each morning; do the day; tick it off.
- [`01-domain-checklists.md`](01-domain-checklists.md) — your mastery tracker. Mark each competency `[ ] → [~] learned → [x] can do timed, closed-book`. You're exam-ready when nearly everything is `[x]`.
- [`02-resources.md`](02-resources.md) — every link, the KodeKloud→domain mapping, how to build your practice cluster, and the exact doc pages to bookmark.
- [`03-exam-day-playbook.md`](03-exam-day-playbook.md) — print/skim the morning of the exam: shell setup, .vimrc, the gotcha list, and the Top-15 lessons.

## After the plan

Once this plan is proven out, the next step (per the repo roadmap) is to build a **CKS practice resource** — a question/verify/cleanup lab harness mirroring `cka/practice-cli/`, seeded from the domain checklists here.
