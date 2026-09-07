# Q16. Detect Threats with Falco Rules

**Host:** the worker node named in the setup output, as root (`ssh` to it, then `sudo -i`).

Falco runs on that node, but `/etc/falco/falco_rules.local.yaml` holds no rules of your own.
Deployment `shell-bot` in namespace `falco-lab` runs on the same node and execs a shell
inside its container every five seconds, and nothing reports it.

1. In `/etc/falco/falco_rules.local.yaml`, add a rule named `Shell spawned in container`:
   - `condition`: an exec (`spawned_process`, or `evt.type = execve`) of a shell binary
     (`proc.name in (bash, sh)`, or the `shell_binaries` list) inside a container, never on
     the host (`container.id != host`, or the `container` macro).
   - `output`: text that starts with `Shell spawned in container` and includes
     `container=%container.name` and `proc=%proc.name`.
   - `priority: WARNING`.
2. Reload Falco so it picks the rule up without a full restart:
   `kill -1 $(cat /var/run/falco.pid)`.
3. Confirm the alert fires for `shell-bot`:
   `journalctl -u falco-modern-bpf -u falco -f | grep 'Shell spawned in container'`.
