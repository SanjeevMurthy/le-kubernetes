#!/usr/bin/env python3
"""Cleanups must undo their own question and nothing else.

Three defects found during the LFCS build all had the same shape: a cleanup
reaching beyond what its setup created. One deleted user accounts the host
already had, one flushed every firewall rule on the machine, and one restored a
whole-file snapshot of /etc/fstab that did not know about the other questions'
mounts. The last of those can leave a virtual machine that will not boot.

Each is cheap to detect, so detect it rather than trusting the next author to
remember. Every rule here is a bug that actually happened.

Usage: python3 scripts/check-cleanup-safety.py [cks|lfcs]
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

def unguarded_deletions(text):
    """Lines deleting an account with no nearby record of having created it.

    Checked line by line rather than per file: a cleanup that guards one
    account and deletes three others unconditionally is the exact bug this
    exists to catch, and a whole-file search would call it clean.
    """
    lines = text.splitlines()
    bad = []
    for i, line in enumerate(lines):
        if not re.match(r'\s*(userdel|groupdel)\b', line):
            continue
        window = "\n".join(lines[max(0, i - 6):i + 1])
        if "created" not in window:
            bad.append((i + 1, line.strip()))
    return bad


RULES = [
    # (regex over the file, message, exemption predicate)
    (re.compile(r'\bnft\s+flush\s+ruleset\b'),
     "flushes the whole firewall ruleset, which erases rules docker, libvirt, "
     "podman or ufw installed and this question never created; delete only the "
     "table or chain the question added",
     lambda text: False),
    (re.compile(r'\brestore_file\s+/etc/fstab\b'),
     "restores a whole-file snapshot of /etc/fstab; several storage questions "
     "can be set up at once, so that snapshot deletes their mounts and can "
     "leave the machine unbootable. Use fstab_drop_target instead",
     lambda text: False),
]


def main(argv):
    kits = [a for a in argv if a in ("cks", "lfcs")] or ["cks", "lfcs"]
    problems = 0
    checked = 0
    for kit in kits:
        qdir = ROOT / kit / "practice-cli" / "questions"
        if not qdir.is_dir():
            continue
        for c in sorted(qdir.glob("q*/cleanup.sh")):
            if c.stat().st_size == 0:
                continue
            checked += 1
            text = c.read_text()
            rel = c.relative_to(ROOT)
            for lineno, line in unguarded_deletions(text):
                print(f"  {rel}:{lineno} deletes an account with no record that "
                      f"this question created it: {line}")
                problems += 1
            for pattern, message, exempt in RULES:
                if pattern.search(text) and not exempt(text):
                    print(f"  {rel} {message}")
                    problems += 1
    print(f"check-cleanup-safety: {checked} cleanup(s), {problems} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
