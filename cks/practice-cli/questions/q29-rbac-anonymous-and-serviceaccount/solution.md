# Q29. Remove anonymous access and scope the ServiceAccount (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. Find every ClusterRoleBinding that names `system:anonymous`.** Do not guess the binding's name. There is no `jq`, so use a go-template.

```bash
kubectl get clusterrolebinding -o go-template='{{range .items}}{{$n := .metadata.name}}{{if .subjects}}{{range .subjects}}{{if eq .name "system:anonymous"}}{{$n}}{{"\n"}}{{end}}{{end}}{{end}}{{end}}'
```

That prints `anon-viewer`. Remove it:

```bash
kubectl delete clusterrolebinding anon-viewer
```

Run the search again; it must print nothing.

**2. Find what binds the ServiceAccount.** Same idea, filtered on the subject kind.

```bash
kubectl get clusterrolebinding -o go-template='{{range .items}}{{$n := .metadata.name}}{{if .subjects}}{{range .subjects}}{{if eq .kind "ServiceAccount"}}{{if eq .name "reporter"}}{{$n}}{{"\n"}}{{end}}{{end}}{{end}}{{end}}{{end}}'

kubectl delete clusterrolebinding reporter-admin
```

**3. Grant the narrow permissions back.** Imperative commands are faster than YAML and are exactly what the exam expects here.

```bash
kubectl create role reporter \
  --verb=get,list --resource=pods,services -n rbac-lab

kubectl create rolebinding reporter \
  --role=reporter --serviceaccount=rbac-lab:reporter -n rbac-lab
```

Note `--serviceaccount=<namespace>:<name>` on the RoleBinding, not `--user`.

**4. Prove it, both ways.** The negative answers matter as much as the positive ones.

```bash
SA=system:serviceaccount:rbac-lab:reporter
kubectl auth can-i get    pods     --as=$SA -n rbac-lab   # yes
kubectl auth can-i list   services --as=$SA -n rbac-lab   # yes
kubectl auth can-i delete pods     --as=$SA -n rbac-lab   # no
kubectl auth can-i get    nodes    --as=$SA               # no
kubectl auth can-i list   pods     --as=$SA -n kube-system # no
```

## Why

`system:anonymous` is the identity the API server assigns to any request that carries no credentials, and it is a member of the `system:unauthenticated` group. Binding it to `view` turns "unauthenticated" into "reads everything", which is worse than it looks: `view` covers ConfigMaps, and ConfigMaps are where people leave connection strings. Deleting the binding is the fix; `--anonymous-auth=false` on the API server is the other half, and that is Q6.

The search matters more than the deletion. A single named binding is easy, but the finding is "no ClusterRoleBinding may have this subject", and a cluster can accumulate several. Listing subjects with a go-template is the habit to build, because `kubectl get clusterrolebinding` on its own shows only the role, never who is bound.

For the ServiceAccount, a Role plus RoleBinding confines the grant to one namespace. A ClusterRole bound with a RoleBinding would also work and is sometimes the right answer, but a ClusterRoleBinding never is: it applies the permissions in every namespace at once, which is how `list pods -n kube-system` stays a yes when you thought you had scoped it.

`kubectl auth can-i --as=` asks the API server's authorizer the same question the authorizer will answer at request time, so it accounts for every binding that applies, including ones you did not know about. Checking only the permissions that must exist is half a test. Least privilege is defined by what is refused.

## Verify

```bash
kubectl get clusterrolebinding anon-viewer     # NotFound
kubectl get clusterrolebinding reporter-admin  # NotFound
kubectl -n rbac-lab get role,rolebinding

SA=system:serviceaccount:rbac-lab:reporter
for q in "get pods" "list services"; do kubectl auth can-i $q --as=$SA -n rbac-lab; done   # yes yes
kubectl auth can-i delete pods --as=$SA -n rbac-lab   # no
kubectl auth can-i get nodes   --as=$SA               # no
```

## Docs

**Allowed:** `https://kubernetes.io/docs/reference/access-authn-authz/rbac/` for the subject kinds and the binding rules, and `https://kubernetes.io/docs/concepts/security/rbac-good-practices/` for why anonymous binding is called out.

Worth memorising: `kubectl create role --verb= --resource= -n`, `kubectl create rolebinding --role= --serviceaccount=<ns>:<name> -n`, the subject name `system:anonymous`, the group `system:unauthenticated`, and `kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<ns>:<sa> -n <ns>`.
