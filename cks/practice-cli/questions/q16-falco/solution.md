# Q16. Detect Threats with Falco Rules (solution)

## Steps

Falco runs on the worker, not on `base`, and not in the cluster. Get onto the right host first. Every reported failure on this task family starts with somebody editing a rules file on the control plane.

```bash
ssh <worker>            # the name the setup printed
sudo -i
hostname                # confirm before you edit anything
```

**1. Find out which unit is running.** Recent packages ship `falco-modern-bpf`; older ones ship plain `falco`. Knowing which decides how you reload it and where you read the alerts.

```bash
systemctl list-units --type=service | grep -i falco
systemctl is-active falco-modern-bpf || systemctl is-active falco
```

**2. Confirm the field names before using them.** Falco prints every field it knows. This costs five seconds and removes the single most common reason a rule fires but the output is wrong.

```bash
falco --list | grep -E 'container.name|proc.name|container.id'
```

**3. Write the rule in the local file.** `/etc/falco/falco_rules.local.yaml` is the override file and is loaded after the shipped rules. Adding rules there rather than editing `falco_rules.yaml` means a package upgrade does not silently discard your work, and it is what the task asks for.

```bash
cat >> /etc/falco/falco_rules.local.yaml <<'EOF'
- rule: Shell spawned in container
  desc: Detect a shell spawned inside a container
  condition: spawned_process and container and proc.name in (bash, sh)
  output: "Shell spawned in container (container=%container.name proc=%proc.name user=%user.name)"
  priority: WARNING
EOF
```

Three things in that `condition` each earn their place:

- `spawned_process` is the macro for `evt.type = execve`. Writing the raw form works too.
- `container` is the macro for `container.id != host`. Without it the rule fires on every shell on the node, your own included, and the journal fills with your own `ssh` session.
- `proc.name in (bash, sh)` is the shell test. The shipped `shell_binaries` list is broader and is also accepted here.

**4. Validate before you reload.** A syntax error does not produce a warning; it stops Falco from starting. A Falco that is not running scores zero on a question about detection, and you will not notice until you look for alerts that never arrive.

```bash
falco --validate /etc/falco/falco_rules.local.yaml
```

**5. Reload.** `SIGHUP` re-reads the rules without dropping the process, which is what the task asks for. Restarting the unit works too and is the fallback when the pid file is missing.

```bash
kill -1 "$(cat /var/run/falco.pid)" \
  || systemctl restart falco-modern-bpf 2>/dev/null \
  || systemctl restart falco
```

**6. Confirm it survived, and that the alert fires.** Both halves matter. A rule that loaded but never fires and a Falco that died on your edit look identical if you only check one.

```bash
systemctl is-active falco-modern-bpf || systemctl is-active falco

journalctl -u falco-modern-bpf -u falco -f | grep 'Shell spawned in container'
```

`shell-bot` execs a shell every five seconds, so an alert should appear almost immediately. If nothing comes within fifteen seconds, the rule did not load.

## When no alert arrives

Work down this list rather than rewriting the rule:

```bash
# Is Falco even running?
systemctl status falco-modern-bpf falco --no-pager | head -20

# Did it load your file? The startup line names every rules file it read.
journalctl -u falco-modern-bpf -u falco | grep -i 'rules file\|loading\|error' | tail

# Is the rule registered under the name you expect?
falco --list-rules 2>/dev/null | grep -i 'shell spawned'
```

A rule silently ignored is nearly always one of: a name that duplicates a shipped rule without matching it exactly, a `condition` referencing a macro that does not exist on this build, or YAML indentation that made your rule a key of the previous one.

## Mapping an alert back to a Pod

The alert gives you a container, and the question after this one usually asks for a Pod. On a node with containerd, `crictl` is the bridge, and it is worth having in your fingers because `kubectl` cannot do it from the node:

```bash
crictl ps --id <container.id>
crictl inspect <container.id> | grep -i 'io.kubernetes.pod.name\|io.kubernetes.pod.namespace'
```

Q31 is the question that turns that into finding and stopping the offending workload, and Q19 is the one that changes the output format. This one is the rule itself.

## Gotchas

- Editing the file proves nothing. Falco holds its rules in memory, so without the reload the file on disk and the running configuration disagree, and the verifier tests the running one.
- File output is off by default in `/etc/falco/falco.yaml`. Alerts go to the journal unless `file_output` is enabled, which is why `journalctl` rather than a log file is where you look.
- The unit name differs between builds. Write both into any command you run: `journalctl -u falco-modern-bpf -u falco`.
- `%container.name` is empty for a process on the host. If your alerts show a blank container, the `container` macro is missing from the condition.
- Overriding a shipped rule requires re-declaring it under exactly the same `rule:` name. A different name creates a second rule, and both fire.
- Falco's own documentation *is* allowed in the exam. `falco.org/docs` is on the list, unlike Trivy's or AppArmor's, so this is one of the few tools you can look up rather than memorise.

## Docs

- https://falco.org/docs/rules/ for rule fields, macros and lists (allowed in the exam)
- https://falco.org/docs/reference/rules/supported-fields/ for the field names `falco --list` prints
- `man 1 journalctl`, in particular `-u`, `-f` and `--since`
