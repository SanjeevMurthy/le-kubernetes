# Q48. Gatekeeper: allow images from one registry only

**Host:** any host with `kubectl`, against a cluster where Gatekeeper is already installed.

OPA Gatekeeper is running. A `ConstraintTemplate` named `k8sallowedrepos` is already defined, and a constraint named `allowed-registries` already uses it against namespace `supply-lab`. As it stands the constraint permits Docker Hub, which is the opposite of what the platform team asked for.

Do **not** install, reinstall or upgrade Gatekeeper, and do not edit the ConstraintTemplate. Change the constraint only.

1. Edit the `K8sAllowedRepos` constraint named `allowed-registries` so that the only permitted image prefix is `registry.k8s.io/`.

2. Leave its scope as it is: namespace `supply-lab`, Pods only.

3. Leave its enforcement as a hard denial, not a warning or an audit.

Afterwards a Pod using a `docker.io/...` or bare `nginx` image must be refused in `supply-lab`, a Pod using `registry.k8s.io/...` must be accepted there, and namespace `supply-other` must be unaffected.
