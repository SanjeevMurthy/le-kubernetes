# Q8. Seccomp RuntimeDefault + Custom Profile

Run pod `audited` using the `RuntimeDefault` seccomp profile. Then run pod `custom` using a custom seccomp profile located at `profiles/audit.json` under the kubelet seccomp directory. Verify both pods run.
