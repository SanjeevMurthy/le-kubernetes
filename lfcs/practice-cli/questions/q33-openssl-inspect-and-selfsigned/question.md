# Q33. Read a certificate and issue a self-signed one

Part one. Another team handed over the certificate `/opt/course/33/server.crt` (`$COURSE_DIR/33/server.crt` on this lab) and wants two facts about it.

1. Write to `/opt/course/33/answer.txt` the certificate's common name and its `notAfter` date, exactly as `openssl` prints the date. Two lines are enough, and nothing else is read from the file.

Part two. A lab service on this host needs a certificate of its own.

2. Create `/etc/ssl/lab` and put a self-signed certificate and its private key there as `lab.crt` and `lab.key`.
3. The key must be RSA 2048. The subject common name must be `lab.local`. The certificate must be valid for 365 days.
4. The service starts unattended, so the key must carry no passphrase. The key must be owned by root with mode `600`.

The grader reads `answer.txt`, `openssl x509`, `openssl rsa` and `stat`, and it compares the modulus of the key with the modulus of the certificate. A key that does not belong to the certificate fails, and so does a key any account other than root can read.
