#!/usr/bin/env python3
"""One-off migration: split cks-exam-qa-guide.md into per-question files.

Writes questions/qNN-*/question.md and solution.md. Delete this script once
tools/build-guide.sh regenerates the guide from those files.
"""
import glob
import os
import re
import sys

cli = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
guide = open(os.path.join(cli, 'cks-exam-qa-guide.md'), encoding='utf-8').read()
parts = re.split(r'^### Q(\d+)\. (.+)$', guide, flags=re.M)
count = 0
for i in range(1, len(parts), 3):
    num, title, body = int(parts[i]), parts[i + 1].strip(), parts[i + 2]
    body = re.split(r'^## DOMAIN', body, flags=re.M)[0]
    m = re.search(r'\*\*Question:\*\*\s*(.*?)(?=\n\*\*Concept|\n\*\*Solution)', body, re.S)
    question = m.group(1).strip() if m else body.strip()
    m2 = re.search(r'(\*\*Concept.*)', body, re.S)
    solution = m2.group(1).strip() if m2 else ''
    folders = glob.glob(os.path.join(cli, 'questions', 'q%02d-*' % num))
    if len(folders) != 1:
        print('no unique folder for Q%d' % num)
        sys.exit(1)
    with open(os.path.join(folders[0], 'question.md'), 'w', encoding='utf-8') as fh:
        fh.write('# Q%d. %s\n\n%s\n' % (num, title, question))
    with open(os.path.join(folders[0], 'solution.md'), 'w', encoding='utf-8') as fh:
        fh.write('# Q%d. %s (solution)\n\n%s\n' % (num, title, solution))
    count += 1
    print('Q%d -> %s' % (num, os.path.basename(folders[0])))
print('split %d questions' % count)
