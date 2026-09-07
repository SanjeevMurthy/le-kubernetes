# Q36. Pod Security: enforce baseline and report violators

**Host:** the cluster you are already on. No node access is needed.

Namespace `psa-lab` already runs three pods and no Pod Security Standard is enforced on it.

1. Label `psa-lab` so that the **baseline** standard is enforced.

2. `enforce` only applies to pods that are created after the label is set. The pods that are already running are never evicted by it, so the cluster is left with workloads that would no longer be admitted. Find out **which of the pods currently in `psa-lab` violate baseline** and write their names to `/opt/course/36/violators.txt` (or `$COURSE_DIR/36/violators.txt` on this lab):

   - one name per line,
   - the pod name only, with no namespace and no other text,
   - sorted alphabetically.

Not every pod in the namespace violates the standard. A list of all three is wrong.

3. Leave the three pods running. Do not delete or edit them.
