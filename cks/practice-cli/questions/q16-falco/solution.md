# Q16. Detect Threats with Falco Rules (solution)

**Concept & Explanation:**

Falco evaluates kernel syscall events against rules. Custom rules go in `/etc/falco/falco_rules.local.yaml` (so defaults stay intact). A rule has `condition` (Falco fields), `output`, and `priority`. Falco must reload to pick up changes — `SIGHUP` reloads without dropping the process.

**Solution — Step by Step:**

```yaml
# /etc/falco/falco_rules.local.yaml
- rule: Shell In Container
  desc: Detect a shell spawned inside a container
  condition: container.id != host and proc.name in (bash, sh)
  output: "Shell in container (container=%container.name proc=%proc.name user=%user.name)"
  priority: WARNING
```
```bash
# Reload without full restart
sudo kill -1 $(cat /var/run/falco.pid)        # SIGHUP
# Trigger + observe
kubectl exec -it <somepod> -- sh
sudo journalctl -fu falco | grep "Shell in container"
```

**Key Points to Remember:**

- Put custom rules in `falco_rules.local.yaml`, not the default file.
- **Reload after editing** (`kill -1 $(cat /var/run/falco.pid)` or `systemctl reload falco`) or the rule won't fire.
- Output fields use `%field`; common ones: `%container.name`, `%proc.name`, `%fd.name`, `%user.name`.

**Official Documentation:**
- https://falco.org/docs/rules/ (falco.org allowed in-exam)

---
