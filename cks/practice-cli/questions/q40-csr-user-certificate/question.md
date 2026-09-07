# Q40. Issue a client certificate to user jane and bind a Role

**Host:** any host with `kubectl` and `openssl`. Work in `/opt/course/40/` (or `$COURSE_DIR/40/` on this lab).

A new colleague, `jane`, needs read access to the Pods in namespace `csr-lab` and nothing else. The cluster has no identity provider, so her identity comes from a client certificate signed by the cluster CA through the CertificateSigningRequest API.

1. Create a 2048-bit RSA key at `jane.key` and a certificate request at `jane.csr` with subject `/CN=jane`. The common name is the username the API server will see.

2. Create a CertificateSigningRequest object named `jane`:

   - `signerName: kubernetes.io/kube-apiserver-client`
   - `usages: ["client auth"]`
   - `request:` the contents of `jane.csr`, base64 encoded on a single line

3. Approve the request and write the issued certificate to `jane.crt` in the same directory.

4. Grant `jane` `get` and `list` on `pods` in namespace `csr-lab` with a Role and a RoleBinding. The grant must be namespaced: do not create a ClusterRole or a ClusterRoleBinding.

Afterwards `jane` must be able to list Pods in `csr-lab`, and must **not** be able to read Secrets in `csr-lab` or list Pods anywhere else.
