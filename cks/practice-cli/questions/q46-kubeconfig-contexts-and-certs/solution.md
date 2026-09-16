# Q46. Read the contexts and decode the certificate inside a kubeconfig (solution)

## Steps

Every command below points `kubectl` at the handed-over file with `--kubeconfig`. That flag is the whole trick: it reads that file and leaves your own alone. Exporting `KUBECONFIG` for the shell works too, but it stays set for the next task, which is how people end up solving question 7 against the wrong cluster.

```bash
cd /opt/course/46
```

**1. List the context names.** `-o name` prints the names alone. Without it you get the table, with its `CURRENT`, `NAME`, `CLUSTER` and `AUTHINFO` columns and a `*` on the current row, none of which is a context name.

```bash
kubectl --kubeconfig kubeconfig config get-contexts -o name > contexts
cat contexts
```

```
blue-cluster-admin
green-cluster-restricted
orange-cluster-audit
```

**2. The current context.** This is the file's own `current-context` field, which is not your shell's.

```bash
kubectl --kubeconfig kubeconfig config current-context > current
cat current
```

```
green-cluster-restricted
```

**3. Pull the certificate out.** It is stored base64 encoded under the user's `client-certificate-data`. Ask for that one field by jsonpath, decode it, and you have PEM on stdout.

```bash
kubectl --kubeconfig kubeconfig config view --raw \
  -o jsonpath='{.users[?(@.name=="green-restricted")].user.client-certificate-data}' \
  | base64 -d > /tmp/green.crt
```

`--raw` is not optional. Without it `kubectl config view` redacts every credential and prints `DATA+OMITTED` where the certificate should be, and `base64 -d` then fails on something that was never base64.

**4. Read its subject.**

```bash
openssl x509 -in /tmp/green.crt -noout -subject
```

```
subject=CN = restricted-7261, O = incident-reviewers
```

**5. Write the two deliverables.** The task asked for the values alone, so strip the `CN =` and `O =` labels.

```bash
openssl x509 -in /tmp/green.crt -noout -subject \
  | sed -n 's/.*CN *= *\([^,]*\).*/\1/p' | tr -d ' ' > cert-cn
openssl x509 -in /tmp/green.crt -noout -subject \
  | sed -n 's/.*O *= *\([^,]*\).*/\1/p' | tr -d ' ' > cert-group
cat cert-cn cert-group
```

Doing it in one pipeline is fine, but under time pressure it is usually quicker to run the `openssl` line once, read the subject with your eyes, and `echo` the two values into the files.

## Why the CN and the O matter

This is not a certificate-parsing exercise dressed up as Kubernetes. When a client certificate authenticates to the API server:

- the **Common Name becomes the username**
- each **Organization becomes a group**

So the certificate above is user `restricted-7261` in group `incident-reviewers`, and every RBAC decision for that client is made against those two strings. Nothing in the cluster records them anywhere else, which is why reading a kubeconfig is how you answer "who is this, and what were they allowed to do" during a review. It is also why you cannot change someone's username by editing the kubeconfig: the name lives inside a signed certificate, and editing it invalidates the signature.

The same reasoning is behind Q40, which issues one of these through a CertificateSigningRequest. Q46 reads one; Q40 writes one.

## Gotchas

- `config view` redacts by default. `--raw` is what makes it print the real data, and forgetting it is the single most common way this task goes wrong.
- A user may carry `client-certificate` (a path on disk) instead of `client-certificate-data` (embedded base64). Look at the file before assuming which, and if it is a path, skip the decode and run `openssl x509 -in <path>` directly.
- `base64 -d` on Linux is `base64 -D` on macOS. The exam hosts are Linux.
- Do not `export KUBECONFIG` for this. If you do, unset it before the next task.
- Copying the file to `~/.kube/config` "so kubectl can read it" replaces your own credentials with someone else's. The verifier checks that your context was not switched, because in the exam that mistake costs you the questions that follow, not this one.
- `jsonpath` with a filter needs the double quotes inside the single-quoted expression exactly as written: `{.users[?(@.name=="green-restricted")]...}`.

## Docs

`kubernetes.io/docs` is allowed in the exam and covers both pages below. `man openssl-x509` is on every host.

- https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
- https://kubernetes.io/docs/reference/access-authn-authz/authentication/#x509-client-certs for the CN-is-the-user and O-is-the-group rule
- `man 1 openssl-x509`, the `-subject` and `-noout` options
