# LFCS Study Notes

Seven notes covering the whole LFCS curriculum, written as **exam-task recipes** rather than reference material. Each recipe states the goal, how often the task is reported, the exact commands for both distribution families, how to verify, the traps, and the man page to read when you cannot remember.

<!-- toc -->
## Table of Contents

- [Read in this order](#read-in-this-order)
- [The structure of a recipe](#the-structure-of-a-recipe)
- [How to use them](#how-to-use-them)
- [Related](#related)

<!-- toc stop -->

## Read in this order

| # | Note | Weight | Recipes |
|---|---|---|---|
| 00 | [The exam environment](00-exam-environment.md) | — | facts only; read first |
| 06 | [Linux basics refresher](06-linux-basics-refresher.md) | — | the assumed knowledge |
| 04 | [Essential Commands](04-essential-commands.md) | 20% | 9 |
| 05 | [Users and Groups](05-users-and-groups.md) | 10% | 6 |
| 01 | [Operations Deployment](01-operations-deployment.md) | 25% | 11 |
| 03 | [Storage](03-storage.md) | 20% | 9 |
| 02 | [Networking](02-networking.md) | 25% | 11 |

The order is deliberate and not numeric. Essential Commands and Users come first because they are quick wins that build muscle memory. Networking comes last because it is the largest, the most distribution-divergent, and the easiest to practise once the lab habits are in place. Follow [`../study-plan/00-calendar.md`](../study-plan/00-calendar.md).

## The structure of a recipe

Every recipe in every note uses the same six blocks:

- **Goal** — the end state a grader would check
- **Frequency** — how many independent candidate reports mention this task type, and which question drills it
- **Commands** — the exact sequence, with Ubuntu and Rocky forms where they differ
- **Verify** — the machine-readable command that proves it, and separately that it persists
- **Gotchas** — what other candidates got wrong
- **Docs** — the man page and section to read, because there is no browser

That last block is the one to internalise. In the Kubernetes exams the `Docs` line points at a website. Here it points at `man 5 fstab`, and if you cannot find that page quickly, the knowledge does not help.

## How to use them

1. **Read** one note's recipes at the start of its week, with the lab VM running.
2. **Type** every command yourself, on both VMs where the note gives two forms.
3. **Drill** the matching practice questions until each is under 6 minutes: [`../practice-cli/`](../practice-cli/).
4. **Reboot the VM** and re-run the verifier. Anything that fails was never persistent.
5. **Card** every line of each `## Memorise` section into [`../cheatsheets/lfcs-anki-deck.txt`](../cheatsheets/lfcs-anki-deck.txt).
6. **Re-score** [`../study-plan/01-domain-checklists.md`](../study-plan/01-domain-checklists.md).

## Related

- [`../cheatsheets/man-page-navigation.md`](../cheatsheets/man-page-navigation.md) — the skill that replaces a browser
- [`../lab-setup/README.md`](../lab-setup/README.md) — where to run all of this
- [`../../docs/research/2026-09-06-lfcs-exam-research.md`](../../docs/research/2026-09-06-lfcs-exam-research.md) — every frequency number's source
