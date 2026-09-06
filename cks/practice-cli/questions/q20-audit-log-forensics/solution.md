# Q20. Audit log forensics: who deleted the Secret (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

Set the log path once. On a real exam host this is `/opt/course/20/audit.log`.

```bash
LOG=/opt/course/20/audit.log
```

**1. Find the deletion.** Filter on all four facts at once. Filtering on the verb alone is not enough, because other Secrets were deleted in the same window.

```bash
grep '"verb":"delete"' "$LOG" | grep '"resource":"secrets"' \
  | grep '"name":"db-creds"' | grep '"namespace":"finance"'
```

That returns exactly one line. Confirm it is one:

```bash
grep '"verb":"delete"' "$LOG" | grep '"resource":"secrets"' \
  | grep '"name":"db-creds"' | grep '"namespace":"finance"' | wc -l
```

**2. Pull the three fields out of that line.** There is no `jq`, so use `grep -o` and `cut`.

```bash
DEL=$(grep '"verb":"delete"' "$LOG" | grep '"resource":"secrets"' \
      | grep '"name":"db-creds"' | grep '"namespace":"finance"')

echo "$DEL" | grep -o '"username":"[^"]*"' | cut -d'"' -f4
echo "$DEL" | grep -o '"sourceIPs":\["[^"]*"' | cut -d'"' -f4
echo "$DEL" | grep -o '"requestReceivedTimestamp":"[^"]*"' | cut -d'"' -f4
```

`yq` is installed and also works, one line at a time:

```bash
echo "$DEL" | yq -p json '.user.username, .sourceIPs[0], .requestReceivedTimestamp'
```

**3. Count the reads.**

```bash
grep '"verb":"get"' "$LOG" | grep '"name":"db-creds"' | grep -c '"namespace":"finance"'
```

**4. Write the deliverable.**

```bash
mkdir -p /opt/course/20
cat > /opt/course/20/answer.txt <<EOF
user=mallory
ip=10.44.0.7
time=2026-11-14T02:41:07.884213Z
gets=7
EOF
```

Substitute the values you actually found; the ones above are from one generated log.

## Why

Audit events are one compact JSON object per line, which is what makes line-oriented tools work at all. Every event carries `user.username`, `sourceIPs`, `verb`, `objectRef` (resource, namespace, name) and `requestReceivedTimestamp`, so a single line answers who, from where, what and when.

The reason to filter on four fields rather than one is that a real log is mostly noise. Here there are three deletions of Secrets and only one of them is the target. On the exam the same is true at a larger scale, and a broad grep that returns twelve lines costs more time than a narrow one that returns one.

Reads are counted separately because `get` on a Secret returns its contents. The count tells you how widely the value may have leaked before it was deleted, which is the question an investigator actually cares about.

## Verify

```bash
cat /opt/course/20/answer.txt
grep '"verb":"delete"' "$LOG" | grep '"name":"db-creds"' | grep -c '"namespace":"finance"'   # 1
```

## Docs

None needed, and none would help. This is a text-processing task under time pressure. What matters is knowing the audit event field names by heart, which is why they are in the `## Memorise` section of `../../study-notes/06-monitoring-logging-runtime.md`.

Note the contrast worth remembering: a kube-apiserver **audit log** is compact JSON, so `grep '"verb":"delete"'` matches. The output of `kubectl -o json` is pretty-printed, so the same pattern never matches there. Use `-o jsonpath` against the API and line tools against the log.
