# CKA - Certified Kubernetes Administrator

## Exam Domains & Weights (2025)

| Domain | Weight |
|--------|--------|
| Cluster Architecture, Installation & Configuration | 25% |
| Workloads & Scheduling | 15% |
| Services & Networking | 20% |
| Storage | 10% |
| Troubleshooting | 30% |

## Directory Structure

```
cka/
├── cheatsheets/          # Quick-reference guides for exam day
├── study-guide/          # Exercises organized by exam domain
│   ├── 1-core-concepts/
│   ├── 2-workloads-scheduling/
│   ├── 3-services-and-networking/
│   └── 4-storage/
├── course-notes/         # Udemy course notes & YAML examples
│   ├── scheduling/
│   ├── networking/
│   ├── security/
│   └── helm/
├── practice-cli/         # Interactive CLI exam simulators
│   ├── v1/               # 17 questions
│   └── v2/               # 22 questions (recommended)
├── practice-tests/       # Practice tests from multiple sources
│   ├── udemy/            # KodeKloud mock exam solutions
│   ├── killercoda/       # Killer.sh simulator guides
│   └── exam-questions/   # Real exam question analysis & study plans
├── troubleshooting/      # Troubleshooting scenarios & companion PDF
└── resources/            # PDFs and reference materials
```

## Quick Start

```bash
# Run the CKA practice CLI (requires a running K8s cluster)
cd cka/practice-cli/v2
chmod +x cka
./cka
```

## Study Resources

- [Exam Cheatsheet](cheatsheets/cka-exam-cheatsheet.md) - Command reference for exam day
- [Kubectl Imperative Commands](cheatsheets/kubectl-imperative-commands.md) - Comprehensive imperative command reference
- [Exam Readiness Checklist](cheatsheets/exam-readiness.md) - Pre-exam review
- [Troubleshooting Scenarios](troubleshooting/troubleshooting-scenarios.md) - Common cluster issues
