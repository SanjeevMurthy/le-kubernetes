# Q27. Fix two issues in the Dockerfile and two in the manifest (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. Read both files first.** Four lines change in total, so find them before typing anything.

```bash
cd /opt/course/27
cat -n Dockerfile
cat -n deploy.yaml
```

**2. Dockerfile, problem one: the base image.** `ubuntu:16.04` went end of life in April 2021 and receives no security updates, so every CVE in it is permanent. Stay on the same distribution, as the task asks, and move to a supported tag.

```
FROM ubuntu:16.04
```
becomes
```
FROM ubuntu:24.04
```

**3. Dockerfile, problem two: the final `USER`.** The image already creates `appuser` with UID 10001, then throws that away by ending on `USER root`. The last `USER` instruction is the one the container starts with.

```
USER root
```
becomes
```
USER appuser
```

`USER 10001` is equally correct and is the better habit, because a numeric UID lets `runAsNonRoot: true` be enforced without the kubelet having to resolve a name.

**4. Manifest, problem one: `privileged: true`.** A privileged container gets every capability, an unmasked `/proc` and the host's devices. It is a container escape waiting to happen.

```yaml
            privileged: false
```

Deleting the line is also accepted, since `false` is the default.

**5. Manifest, problem two: `runAsUser: 0`.** UID 0 in the container is UID 0 on the host for anything that crosses the boundary.

```yaml
            runAsUser: 10001
```

Any non-zero UID passes. Matching the UID baked into the image is what keeps the application able to read its own files.

**6. Check the diff is four lines and nothing else.**

```bash
grep -n 'FROM\|USER' Dockerfile
grep -n 'privileged\|runAsUser' deploy.yaml
wc -l Dockerfile deploy.yaml
```

## Why

Two of these are build-time settings and two are run-time settings, and they fail independently. An image with a perfect `USER` still runs as root if the Pod sets `runAsUser: 0`, because the manifest wins. A manifest with a perfect `securityContext` still ships the CVEs of an end-of-life base image, because no run-time setting patches a library. Supply chain questions test both halves for exactly that reason.

The instruction to change only what is asked is not decoration. Graders diff the file, and an answer that reformats the YAML, reorders keys or "improves" the settings that were already correct loses points even when the four required changes are present. On the real exam this is also a time control: four edits take a minute, a rewrite takes ten and introduces mistakes.

`allowPrivilegeEscalation: false` and `readOnlyRootFilesystem: true` were already in the manifest. Leaving them untouched is part of the answer.

## Verify

```bash
head -1 /opt/course/27/Dockerfile                       # not ubuntu:16.04
grep '^USER' /opt/course/27/Dockerfile | tail -1        # not root
grep -c 'privileged: true' /opt/course/27/deploy.yaml   # 0
grep 'runAsUser' /opt/course/27/deploy.yaml             # not 0
wc -l /opt/course/27/Dockerfile /opt/course/27/deploy.yaml
```

The line counts must stay within 2 of what setup printed.

## Docs

**Memorise.** Nothing here needs a lookup, and opening a browser for it costs more time than the task is worth.

The four facts to carry in: the last `USER` wins in a Dockerfile, `privileged: true` grants everything, `runAsUser: 0` is root regardless of the image, and a base image tag that no longer receives updates is a finding on its own. `https://kubernetes.io/docs/tasks/configure-pod-container/security-context/` has the `securityContext` field names if the spelling escapes you.
