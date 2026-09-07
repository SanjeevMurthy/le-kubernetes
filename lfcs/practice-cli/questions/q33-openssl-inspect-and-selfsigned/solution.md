# Q33. Read a certificate and issue a self-signed one (solution)

## Steps

**1. Read the two fields off the supplied certificate.**

```bash
openssl x509 -in /opt/course/33/server.crt -noout -subject -enddate
```

```
subject=C = IN, ST = KA, L = Bengaluru, O = Shop Ltd, CN = shop.example
notAfter=Sep  5 10:11:12 2036 GMT
```

**2. Write both lines to the deliverable without retyping them.**

```bash
openssl x509 -in /opt/course/33/server.crt -noout -subject -enddate \
  > /opt/course/33/answer.txt
cat /opt/course/33/answer.txt
```

**3. Create the directory and issue the self-signed pair in one command.**

```bash
mkdir -p /etc/ssl/lab
openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
  -keyout /etc/ssl/lab/lab.key \
  -out /etc/ssl/lab/lab.crt \
  -subj "/CN=lab.local"
```

**4. Lock the key down.**

```bash
chown root:root /etc/ssl/lab/lab.key
chmod 600 /etc/ssl/lab/lab.key
```

**5. Prove the key belongs to the certificate.**

```bash
openssl x509 -noout -modulus -in /etc/ssl/lab/lab.crt | openssl sha256
openssl rsa  -noout -modulus -in /etc/ssl/lab/lab.key | openssl sha256
```

The two hashes must be identical.

## Why

`-noout` suppresses the base64 body, which is the only reason the interesting fields stay on screen. `-subject` and `-enddate` together are the whole answer to the reported exam task "report the common name and the expiry", and redirecting that command into the answer file avoids transcription mistakes in a date.

`req -x509` issues a certificate directly instead of a signing request, and `-days` belongs to it because a request carries no validity period at all. `-newkey rsa:2048` generates the key and the certificate in one step, so the two are guaranteed to match. `-nodes` means "no DES", which leaves the private key unencrypted; without it openssl prompts for a passphrase and the service then cannot start without a human typing it at boot.

`-subj` must begin with a slash and separate components with slashes. `CN=lab.local` without the leading slash is rejected outright.

Comparing the modulus is the only reliable proof that a key and a certificate belong together. File names, sizes and timestamps prove nothing, and a mismatched pair fails at the moment the service starts its TLS listener rather than at the moment the files are copied. The same trick works for a signing request with `openssl req -noout -modulus`.

A private key that any account can read is a graded failure on its own, so `chmod 600` is part of the task and not housekeeping. The conventional locations differ by distribution: Ubuntu uses `/etc/ssl/certs` and `/etc/ssl/private`, Rocky uses `/etc/pki/tls/certs` and `/etc/pki/tls/private`. This task names `/etc/ssl/lab` explicitly, so use that path on both.

## Verify

```bash
cat /opt/course/33/answer.txt

openssl x509 -in /etc/ssl/lab/lab.crt -noout -subject -dates
diff <(openssl x509 -noout -modulus -in /etc/ssl/lab/lab.crt) \
     <(openssl rsa  -noout -modulus -in /etc/ssl/lab/lab.key) && echo MATCH
stat -c '%a %U:%G %n' /etc/ssl/lab/lab.key      # expect 600 root:root
openssl x509 -in /etc/ssl/lab/lab.crt -noout -text | grep 'Public-Key'
```

## Docs

- `man 1 openssl` for the command layout, and `openssl x509 -help` or `openssl req -help` for the full option list offline
- `man 1 openssl-x509` for `-noout`, `-subject`, `-enddate`, `-modulus` and `-checkend`
- `man 1 openssl-req` for `-x509`, `-newkey`, `-nodes`, `-days`, `-subj` and `-addext`
- `man 1 openssl-rsa` for reading a private key and printing its modulus
- `man 1 openssl-verify` for validating a certificate against a CA file
- `man 5 config` for the field names that `-subj` uses
