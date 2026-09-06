# CKS Study Notes

Seven notes covering the whole CKS curriculum, written as **exam-task recipes** rather than reference material. Each recipe states the goal, how often the task is reported, the exact commands, how to verify, the traps, and which documentation you are actually allowed to open for it.

The exam environment runs **Kubernetes v1.35**. The published curriculum document is v1.34; the two version numbers refer to different things and both are current.

<!-- toc -->
## Table of Contents

- [Read in this order](#read-in-this-order)
- [How to use them](#how-to-use-them)
- [The structure of a recipe](#the-structure-of-a-recipe)
- [Related](#related)

<!-- toc stop -->

## Read in this order

| # | Note | Weight | Recipes | Drill |
|---|---|---|---|---|
| 00 | [The exam environment](00-exam-environment.md) | — | facts only | read first, re-read before booking |
| 01 | [Cluster Setup](01-cluster-setup.md) | 15% | 8 | Q1, Q2, Q3, Q22, Q24, Q33 |
| 02 | [Cluster Hardening](02-cluster-hardening.md) | 15% | 7 | Q4, Q5, Q6, Q23, Q29, Q37, Q39, Q40 |
| 03 | [System Hardening](03-system-hardening.md) | 10% | 7 | Q7, Q8, Q15, Q30, Q34, Q41, Q42, Q43 |
| 04 | [Minimize Microservice Vulnerabilities](04-microservice-vulnerabilities.md) | 20% | 9 | Q9, Q10, Q11, Q12, Q25, Q26, Q28, Q35, Q36, Q44 |
| 05 | [Supply Chain Security](05-supply-chain-security.md) | 20% | 8 | Q13, Q14, Q15, Q21, Q27, Q38 |
| 06 | [Monitoring, Logging and Runtime Security](06-monitoring-logging-runtime.md) | 20% | 7 | Q16, Q17, Q18, Q19, Q20, Q31, Q32, Q43 |

Notes 04, 05 and 06 are 60 percent of the exam between them. Note 06 contains Falco, the single most reported task family of all.

The calendar deliberately reads them out of numeric order, taking Runtime Security second, because it is the least familiar material and the heaviest weighted. Follow [`../study-plan/00-calendar.md`](../study-plan/00-calendar.md) rather than this table's order.

## How to use them

1. **Read** one note's recipes at the start of its weekend, with the cluster already running.
2. **Type** every command yourself. No copy and paste during the foundation phase; the motor memory is the point.
3. **Drill** the matching practice questions until each is under 8 minutes, closed book: [`../practice-cli/`](../practice-cli/).
4. **Card** every line of the `## Memorise` section. Those sections are the source of [`../cheatsheets/cks-anki-deck.txt`](../cheatsheets/cks-anki-deck.txt).
5. **Re-score** the matching lines in [`../study-plan/01-domain-checklists.md`](../study-plan/01-domain-checklists.md) when you can do them timed.

## The structure of a recipe

Every recipe in every note follows the same six blocks, so you can navigate any of them the same way:

- **Goal** — the end state a grader would check
- **Frequency** — how many independent candidate reports mention this task, and which questions drill it
- **Commands** — the exact sequence, in order
- **Verify** — the command that proves it worked
- **Gotchas** — what other candidates got wrong
- **Docs** — the allowed page to search for, or an explicit statement that no documentation is allowed and the flags must be memorised

That last block matters more than it looks. The exam allows only eight documentation sources, and **Trivy, kube-bench, AppArmor and kubesec are not among them**. Any recipe that says "memorise" is telling you that no amount of searching will help on the day.

## Related

- [`../study-plan/`](../study-plan/) — when to study what, and the mastery checklists
- [`../practice-cli/`](../practice-cli/) — the timed questions with automated verification
- [`../mock-exams/`](../mock-exams/) — three scored 120-minute papers
- [`../cheatsheets/`](../cheatsheets/) — the one-page reference and the Anki deck
- [`../../docs/research/2026-09-06-cks-exam-research.md`](../../docs/research/2026-09-06-cks-exam-research.md) — the 28 candidate reports every frequency number comes from
