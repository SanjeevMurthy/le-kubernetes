# Q7. AppArmor Profile on a Pod

An AppArmor profile named `k8s-deny-write` (denies writes to the filesystem) is provided. Load it on the worker node, then run a pod `secure-pod` whose container is confined by that profile. Confirm the profile is enforced.
