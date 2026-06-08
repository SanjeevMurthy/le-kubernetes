# CKS Study Notes

Concise, practical study guides for the **Certified Kubernetes Security Specialist** exam — ordered exactly as the official CKS curriculum (v1.34, Kubernetes 1.34). Each note explains a topic well enough to **do the task fast under exam pressure**: what it is, why it matters, the commands/examples, and the real exam gotchas. They are study guides, not exhaustive references.

Pair these with the [`../study-plan/`](../study-plan/) (when to study what) and the [`../practice-cli/`](../practice-cli/) (hands-on, verified scenarios). Each note maps to practice-CLI questions in the same domain.

## Read in this order

| # | Note | Weight | Practice CLI |
|---|------|--------|--------------|
| 01 | [Cluster Setup](01-cluster-setup.md) | 15% | Q1–Q3 |
| 02 | [Cluster Hardening](02-cluster-hardening.md) | 15% | Q4–Q6 |
| 03 | [System Hardening](03-system-hardening.md) | 10% | Q7–Q8 |
| 04 | [Minimize Microservice Vulnerabilities](04-microservice-vulnerabilities.md) | 20% | Q9–Q12 |
| 05 | [Supply Chain Security](05-supply-chain-security.md) | 20% | Q13–Q15 |
| 06 | [Monitoring, Logging & Runtime Security](06-monitoring-logging-runtime.md) | 20% | Q16–Q18 |

## How to use them

1. **Read** the note for a domain (active recall: after each topic, close it and re-type the commands).
2. **Drill** the matching practice-CLI questions until you can do each in ≤ 8 minutes.
3. **Revisit** on the spaced-repetition schedule in [`../study-plan/00-daily-schedule.md`](../study-plan/00-daily-schedule.md).
4. Turn every "⚠️ Exam tip" into an Anki card.

> The 20%-weight trio (04, 05, 06) is **60% of the exam** — spend the most time there, especially if you're newer to Falco, Trivy, AppArmor/seccomp, and audit logging.
