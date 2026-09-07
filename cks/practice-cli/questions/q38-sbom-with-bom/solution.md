# Q38. Generate an SBOM and count its packages (solution)

## Steps

**1. Check the tool and the flags before running anything long.**

```bash
bom version
bom generate --help
```

The flags that matter are `--image` for a registry reference, `--format` for `json` or `tag-value`, and `--output` for the file.

**2. Generate the SBOM in JSON.**

```bash
mkdir -p /opt/course/38
bom generate --image registry.k8s.io/kube-proxy:v1.35.0 \
  --format json \
  --output /opt/course/38/sbom.json
```

This pulls the image, so it takes a moment. Without `--format json` the file is SPDX tag-value, which looks like this and is not JSON:

```
SPDXVersion: SPDX-2.3
DataLicense: CC0-1.0
PackageName: kube-proxy
```

**3. Confirm the format before moving on.**

```bash
head -5 /opt/course/38/sbom.json
python3 -c 'import json; json.load(open("/opt/course/38/sbom.json")); print("valid json")'
```

**4. Count the packages.** The outline view prints one line per element, with a box for each package.

```bash
bom document outline /opt/course/38/sbom.json | head -20
bom document outline /opt/course/38/sbom.json | grep -c '📦'
```

Counting straight out of the document is exact and does not depend on the emoji surviving the terminal:

```bash
python3 -c 'import json; print(len(json.load(open("/opt/course/38/sbom.json"))["packages"]))'
```

**5. Write the count, and only the count.**

```bash
python3 -c 'import json; print(len(json.load(open("/opt/course/38/sbom.json"))["packages"]))' \
  > /opt/course/38/count.txt
cat /opt/course/38/count.txt
```

A file containing `packages: 42` fails. The task asked for the number.

## Why

An SBOM is the inventory half of supply chain security. A scanner such as Trivy answers "which known vulnerabilities does this image have today", which is a judgement that changes every time the vulnerability database is updated. An SBOM answers "what is actually inside this image", which does not change. When a new vulnerability is published, the question asked across an estate is not "rescan everything" but "which images contain this package", and only a stored SBOM can answer that quickly.

`bom` is the Kubernetes project's own SPDX tool, which is why it, and not Syft or Trivy, is the one on the exam and the one with a documentation link in the allowed set. It reads three kinds of input: `--image` for a registry reference, `--dirs` for a directory tree, and `--file` for individual files, and it can combine them into a single document.

The format flag is the trap. SPDX is a specification, not a file format, and it has several serialisations. `bom` defaults to tag-value, a plain text form of `Key: value` lines that a human reads easily and a JSON parser rejects immediately. A task that says the SBOM must be JSON is testing whether you noticed the default. Check with a parser, not by eye: tag-value output in a file named `.json` looks fine in `head`.

The count is the second half because an SBOM you cannot query is just a large file. `bom document outline` renders the document as a tree, and the SPDX JSON itself carries a `packages` array that any parser can measure. Both are legitimate. Reach for the parser when the number has to be exact.

## Verify

```bash
python3 -c 'import json; d=json.load(open("/opt/course/38/sbom.json")); print(d["spdxVersion"], len(d["packages"]))'
grep -c kube-proxy /opt/course/38/sbom.json
cat /opt/course/38/count.txt
```

## Docs

**Allowed:** `https://kubernetes-sigs.github.io/bom/cli-reference/` is one of the eight sources open in the exam, and it is the reference for `bom generate` and `bom document`. Every flag used above is on that page, so this task can be solved from documentation alone if the flag names have slipped.

Worth memorising anyway, because looking it up costs a minute: `bom generate --image <ref> --format json --output <file>` and `bom document outline <file>`.
