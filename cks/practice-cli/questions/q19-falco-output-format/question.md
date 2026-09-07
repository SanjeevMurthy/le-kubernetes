# Q19. Falco: change the output format and save the alerts

Falco is running on the worker node. A workload in namespace `falco-lab` is repeatedly reading a sensitive file, which trips the shipped rule **Read sensitive file untrusted**.

On the worker node:

1. Override that rule so its alerts are emitted in exactly this format, and nothing else:

   ```
   %evt.time,%container.id,%container.name,%user.name
   ```

   Keep the rule's name and its priority at `WARNING`. Do not edit `/etc/falco/falco_rules.yaml`.

2. Reload Falco so the change takes effect without losing the service.

3. Collect at least 5 alert lines produced by that rule and write them to `/opt/course/19/falco.log` (or `$COURSE_DIR/19/falco.log` on this lab), one per line, in the format above and nothing else.

Falco documentation is one of the few sources allowed in the exam. The field names are listed under "Supported Fields", and `falco --list` prints them on the host.
