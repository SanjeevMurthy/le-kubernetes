# Q20. Audit log forensics: who deleted the Secret

The Secret `db-creds` in namespace `finance` has disappeared. An API server audit log covering the period has been preserved at `/opt/course/20/audit.log` (or `$COURSE_DIR/20/audit.log` on this lab). Each line is one JSON audit event.

There is no `jq` on this host, exactly as in the exam.

Investigate the log and write your findings to `/opt/course/20/answer.txt`, one per line, in exactly this format:

```
user=<username that deleted the Secret>
ip=<source IP that request came from>
time=<requestReceivedTimestamp of the delete, verbatim>
gets=<how many times db-creds was read with the get verb>
```

Only the deletion of `db-creds` in `finance` counts. Other Secrets were deleted in the same window, and reads of `db-creds` are spread across several users.
