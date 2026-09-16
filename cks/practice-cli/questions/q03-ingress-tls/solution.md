# Q3. Ingress TLS Termination (solution)

## Steps

Nothing here needs a node. Two objects, and a test that has to work around DNS that does not exist.

**1. Look at the certificate you were given.** Confirm it is for the host the Ingress will claim. A certificate for the wrong name produces an Ingress that serves the controller's own fake certificate instead, with no error anywhere.

```bash
cd /opt/course/3
openssl x509 -in web.crt -noout -subject -dates
```

```
subject=CN = secure.example.com
notBefore=...
notAfter=...
```

**2. Create the TLS Secret.** There is a purpose-built imperative command; use it rather than hand-writing base64.

```bash
kubectl -n tls-lab create secret tls web-tls \
  --cert=/opt/course/3/web.crt \
  --key=/opt/course/3/web.key
```

`kubectl create secret tls` is what produces type `kubernetes.io/tls` with the two keys named `tls.crt` and `tls.key`. A generic Secret with the same two files in it is type `Opaque`, and the ingress controller will not use it.

```bash
kubectl -n tls-lab get secret web-tls -o jsonpath='{.type}{"\n"}'
```

**3. Create the Ingress.**

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  namespace: tls-lab
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - secure.example.com
    secretName: web-tls
  rules:
  - host: secure.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web
            port:
              number: 80
EOF
```

The host in `spec.tls[].hosts` must match the host in `spec.rules[].host`. They are two separate lists and nothing warns you when they disagree; TLS simply does not get applied to that rule.

**4. Test it.** There is no DNS for `secure.example.com`, so point curl at the controller and tell it what name to present. This is the part that trips people up, because a plain `curl https://secure.example.com` fails for a reason that has nothing to do with the answer.

```bash
# where the controller is listening
kubectl -n ingress-nginx get svc ingress-nginx-controller

# NodePort or a minikube IP
IP=$(minikube ip -p cks 2>/dev/null || kubectl get node -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
PORT=$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')

curl -k --resolve "secure.example.com:$PORT:$IP" \
  -o /dev/null -w '%{http_code}\n' "https://secure.example.com:$PORT/"
```

`200` is the pass. `--resolve` fakes the DNS entry for one request, and `-k` accepts the self-signed certificate. Both are needed here and neither hides a real failure.

To confirm which certificate was actually served, rather than only that something answered:

```bash
curl -kv --resolve "secure.example.com:$PORT:$IP" \
  "https://secure.example.com:$PORT/" 2>&1 | grep -E 'subject|issuer'
```

If that shows `CN=Kubernetes Ingress Controller Fake Certificate`, the Secret is not being used: check the type, the name, and that the hosts match.

**5. Confirm the redirect,** since the annotation is part of the answer.

```bash
curl -s -o /dev/null -w '%{http_code}\n' \
  --resolve "secure.example.com:$HTTP_PORT:$IP" \
  "http://secure.example.com:$HTTP_PORT/"
```

`308` is the permanent redirect ingress-nginx issues.

## Making the certificate yourself

Some versions of this question hand you nothing and expect the certificate too. One command:

```bash
openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
  -keyout web.key -out web.crt \
  -subj "/CN=secure.example.com"
```

`-nodes` means no passphrase on the key, which is what a Secret needs; without it the key is encrypted and the controller cannot load it.

## Gotchas

- `kubectl create secret tls`, not `create secret generic`. The type is what the controller looks at.
- The host must appear in both `spec.tls[].hosts` and `spec.rules[].host`.
- `ingressClassName` is a field on `spec` now. The old `kubernetes.io/ingress.class` annotation still works on some controllers but is deprecated, and a question that says "on ingress class nginx" means the field.
- `pathType` is required. Leaving it out is rejected by the API server.
- The backend port is the **Service** port, 80 here, not the container's port.
- Test with `--resolve`. Editing `/etc/hosts` works too but leaves the exam host changed behind you.
- The ingress-nginx user guide is on the exam's allowed list, which is where the annotation names live.

## Docs

- https://kubernetes.io/docs/concepts/services-networking/ingress/#tls
- https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets
- https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/ for `ssl-redirect` and friends (allowed in the exam)
