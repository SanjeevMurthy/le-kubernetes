#!/usr/bin/env python3
"""Every LFCS question must either verify persistence or say why it does not.

The exam's defining rule is that a configuration change which does not survive a
reboot scores zero. A verifier that only checks the running system therefore
grades more generously than the exam does, and practising against it teaches the
wrong habit.

So: each question's verify.sh must call check_persisted, or the question must
appear below with a reason. Adding a question forces that decision to be made
once, in writing, rather than forgotten.

Usage: python3 scripts/check-persistence.py [--list]
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
QDIR = ROOT / "lfcs" / "practice-cli" / "questions"

# Questions whose deliverable genuinely has no on-disk form. Key is the question
# folder's numeric id; the value is why a reboot cannot undo the answer.
EXEMPT = {
    "02": "the answer is a recorded PID and a renice on a running process; nothing is meant to outlive the boot",
    "32": "the deliverable is git history in a repository, which is on disk by definition",
    "33": "the deliverable is a certificate and key file on disk, checked directly",
    "34": "the deliverable is file permissions and ownership, which are on-disk state already",
    "35": "the deliverables are report files written from a log, and files are on disk already",
    "36": "the deliverables are archives and links on disk, which a reboot does not touch",
}


def main(argv):
    if not QDIR.is_dir():
        print("check-persistence: no lfcs question directory - skipped")
        return 0
    missing, exempted, checked = [], [], []
    for d in sorted(QDIR.glob("q*/")):
        v = d / "verify.sh"
        if not v.is_file() or v.stat().st_size == 0:
            continue          # still being written; the refs check catches gaps
        qid = d.name[1:3]
        if "check_persisted" in v.read_text():
            checked.append(d.name)
        elif qid in EXEMPT:
            exempted.append((d.name, EXEMPT[qid]))
        else:
            missing.append(d.name)

    if "--list" in argv:
        for name in checked:
            print(f"  verifies persistence: {name}")
        for name, why in exempted:
            print(f"  exempt: {name} - {why}")

    for name in missing:
        print(f"  {name}/verify.sh never calls check_persisted, and it is not "
              f"listed as exempt in scripts/check-persistence.py")
    print(f"check-persistence: {len(checked)} verified, {len(exempted)} exempt, "
          f"{len(missing)} unaccounted for")
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
