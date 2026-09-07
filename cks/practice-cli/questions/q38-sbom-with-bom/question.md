# Q38. Generate an SBOM and count its packages

**Host:** any Linux host that has `bom` installed. No cluster access is needed, but the host must be able to pull from `registry.k8s.io`.

The supply chain team wants a software bill of materials for the image the cluster runs `kube-proxy` from.

1. Generate an SBOM for `registry.k8s.io/kube-proxy:v1.35.0` and save it to `/opt/course/38/sbom.json` (or `$COURSE_DIR/38/sbom.json` on this lab).

   The file has to be **valid JSON**. `bom` writes SPDX in tag-value form by default, which is not JSON, so the format has to be asked for.

2. Count the packages the SBOM lists and write that number, and nothing else, to `/opt/course/38/count.txt`.

Do not hand-edit the SBOM. It has to be the document `bom` produced.
