# Q40. Issue a client certificate to user jane and bind a Role (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. Key and request.** The subject common name becomes the username, so it has to be exactly `jane`.

```bash
cd /opt/course/40        # or $COURSE_DIR/40 on this lab
openssl genrsa -out jane.key 2048
openssl req -new -key jane.key -out jane.csr -subj "/CN=jane"
```

An organisation would become a group, for example `-subj "/CN=jane/O=developers"`. This task asks for a user only.

**2. Wrap the request in a CertificateSigningRequest.** The `request` field is the whole PEM file, base64 encoded, on one line. A wrapped value is the most common reason this step fails.

```bash
cat > csr.yaml <<YAML
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: jane
spec:
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages:
  - client auth
  request: $(base64 -w0 jane.csr)
YAML

kubectl apply -f csr.yaml
kubectl get csr jane
```

On a system whose `base64` has no `-w0`, use `base64 jane.csr | tr -d '\n'`.

**3. Approve it and take the certificate out.** A new request sits in `Pending` until somebody with rights on `certificatesigningrequests/approval` approves it.

```bash
kubectl certificate approve jane
kubectl get csr jane                       # CONDITION: Approved,Issued

kubectl get csr jane -o jsonpath='{.status.certificate}' | base64 -d > jane.crt
openssl x509 -in jane.crt -noout -subject -issuer -dates
```

The subject line has to read `CN = jane` and the issuer is the cluster CA.

**4. Grant the permissions, scoped to the namespace.**

```bash
kubectl create role pod-reader --verb=get,list --resource=pods -n csr-lab
kubectl create rolebinding jane-pod-reader \
  --role=pod-reader --user=jane -n csr-lab
```

`--user=jane` on the RoleBinding, because the identity is a certificate common name and not a ServiceAccount.

**5. Use the certificate, which is the point of the exercise.**

```bash
kubectl config set-credentials jane \
  --client-key=jane.key --client-certificate=jane.crt --embed-certs=true
kubectl config set-context jane --cluster=kubernetes --user=jane
kubectl --context jane get pods -n csr-lab      # works
kubectl --context jane get secrets -n csr-lab   # Forbidden
```

## Why

The API server has no user database. Every human identity in a kubeadm cluster is either an OIDC token or an x509 client certificate, and for a certificate the API server reads the common name as the username and each organisation as a group. That is the whole of the identity: there is no User object to create, and a certificate with `CN=jane` is `jane` the moment the cluster CA signs it, whether or not any RoleBinding mentions her.

The CertificateSigningRequest API exists so that this signing does not require a shell on the control plane with the CA private key. The candidate keeps the private key, sends only the request, and an approver decides. `signerName` picks which CA and which usage: `kubernetes.io/kube-apiserver-client` issues client certificates the API server trusts for authentication, while `kubernetes.io/kubelet-serving` and `kubernetes.io/kube-apiserver-client-kubelet` exist for the node certificates and must not be used here. The signer also enforces the usages, which is why `client auth` is required and `server auth` would be rejected.

Approval and issuance are two separate conditions. `kubectl certificate approve` sets `Approved`; the controller then signs and fills `.status.certificate`. A request that is approved but has an empty certificate means no signer picked it up, which usually means the `signerName` was wrong. This is worth checking directly rather than trusting the printed `Approved,Issued`.

The last part is the security point. Authentication and authorisation are independent. A signed certificate proves who the caller is and grants nothing at all, so an unbound `jane` can reach the API server and be refused everywhere. Binding a Role rather than a ClusterRole keeps that refusal in place outside `csr-lab`, and binding to Pods only keeps it in place for Secrets inside it. Revocation is the weak spot: Kubernetes has no certificate revocation list, so a leaked client certificate stays valid until it expires. That is why `expirationSeconds` belongs on a request for a human, and why the recovery from a leak is to delete the bindings rather than the certificate.

## Verify

```bash
kubectl get csr jane -o jsonpath='{.status.conditions[*].type}'   # Approved
kubectl get csr jane -o jsonpath='{.status.certificate}' | head -c 20   # not empty
openssl x509 -in /opt/course/40/jane.crt -noout -subject          # CN = jane

kubectl -n csr-lab get role,rolebinding
kubectl auth can-i list pods    -n csr-lab --as jane    # yes
kubectl auth can-i get  secrets -n csr-lab --as jane    # no
kubectl auth can-i list pods    -n kube-system --as jane # no
```

## Docs

**Allowed:** `https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/` carries a complete example of the CertificateSigningRequest object, including the `openssl` lines and the `base64 -w0` trick, and it is the page to open in the exam. `https://kubernetes.io/docs/reference/access-authn-authz/rbac/` covers the `--user` subject on a RoleBinding.

Worth memorising: the four fields of `spec` (`request`, `signerName`, `usages`, optionally `expirationSeconds`), the signer name `kubernetes.io/kube-apiserver-client`, `kubectl certificate approve|deny <name>`, and the extraction pipeline `kubectl get csr <name> -o jsonpath='{.status.certificate}' | base64 -d`.
