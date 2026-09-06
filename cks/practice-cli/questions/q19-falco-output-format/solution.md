# Q19. Falco: change the output format and save the alerts (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

Everything happens on the worker node, as root.

```bash
ssh <worker>
sudo -i
```

**1. Find the rule and its current output.** Never edit the shipped file; you only need to read it.

```bash
grep -A6 'rule: Read sensitive file untrusted' /etc/falco/falco_rules.yaml
```

**2. Confirm the field names.** This is the part worth checking rather than guessing.

```bash
falco --list | grep -E 'evt.time|container.id|container.name|user.name'
```

**3. Override the rule in the local file.** Falco loads `falco_rules.local.yaml` last, so re-declaring a rule with the same name replaces the shipped one. Copy the shipped `condition` across unchanged; only `output` is being changed.

```bash
cat >> /etc/falco/falco_rules.local.yaml <<'EOF'
- rule: Read sensitive file untrusted
  desc: Detect reads of sensitive files by untrusted programs
  condition: >
    sensitive_files and open_read and container
    and not proc_name_exists_in_allowlist
  output: "%evt.time,%container.id,%container.name,%user.name"
  priority: WARNING
  tags: [filesystem, mitre_credential_access]
EOF
```

If the shipped condition references macros that do not resolve, take the exact `condition:` block from step 1 rather than retyping it.

**4. Validate before reloading.** A syntax error takes Falco down, and a Falco that will not start scores zero.

```bash
falco --validate /etc/falco/falco_rules.local.yaml
```

**5. Reload.** The signal reloads rules without dropping the service. Restarting the unit also works.

```bash
kill -1 "$(cat /var/run/falco.pid)" 2>/dev/null \
  || systemctl restart falco-modern-bpf 2>/dev/null \
  || systemctl restart falco
```

Confirm it survived:

```bash
systemctl is-active falco-modern-bpf || systemctl is-active falco
```

**6. Collect the alerts.** The workload trips the rule every three seconds, so a short wait is enough.

```bash
mkdir -p /opt/course/19
journalctl -u falco-modern-bpf -u falco --since '-2 min' --no-pager \
  | grep -oE '[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+,[0-9a-f]+,[^,]+,[^ ]+' \
  | head -10 > /opt/course/19/falco.log

cat /opt/course/19/falco.log
```

If file output is enabled in `/etc/falco/falco.yaml`, read `/var/log/falco.log` instead, which needs no extraction:

```bash
tail -20 /var/log/falco.log
```

## Why

Falco ships its rules in `/etc/falco/falco_rules.yaml` and that file is replaced on upgrade, so any change belongs in `falco_rules.local.yaml`. The local file is loaded last and a rule declared there with an existing name wins outright. That is the whole override mechanism, and it is why the task can be solved without touching the shipped file.

The `output` string is a template. Each `%` field is substituted at alert time from the event, and `falco --list` is the authoritative list of what is available. The four fields asked for here identify when it happened, which container, what that container is called, and who was running as, which is the minimum a responder needs to pivot to the pod.

Reloading with `SIGHUP` rather than a restart matters when a task says to keep Falco running: a restart drops events during the gap, and on a slow node the gap can be long enough that the grader sees no alerts.

## Verify

```bash
grep -A3 'rule: Read sensitive file untrusted' /etc/falco/falco_rules.local.yaml
systemctl is-active falco-modern-bpf || systemctl is-active falco
wc -l /opt/course/19/falco.log     # 5 or more
head -2 /opt/course/19/falco.log   # four comma-separated fields, nothing else
```

## Docs

**Allowed:** `https://falco.org/docs/`. Search "Supported Fields" for the output field names and the rules reference for condition syntax. Falco is one of only eight documentation sources open to you in the exam, so use it rather than guessing field names.

On the host, `falco --list` and `falco -L` need no network at all.
