# Q3. Ingress TLS Termination (solution)

**Concept & Explanation:**

TLS termination at the Ingress means the controller decrypts HTTPS using a certificate and key supplied as a `kubernetes.io/tls` secret, referenced under `spec.tls`. The secret must live in the same namespace as the Ingress, and the host in `spec.tls[].hosts` must match the host in `spec.rules[].host` or the controller serves its own fake certificate.

**Solution — Step by Step:**

```bash
# 1. TLS secret from the certificate the setup left on disk
kubectl create secret tls web-tls -n tls-lab \
  --cert=/opt/course/3/web.crt --key=/opt/course/3/web.key

# 2. Ingress with TLS
kubectl apply -f - <<'YAML'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata: {name: web-ingress, namespace: tls-lab}
spec:
  ingressClassName: nginx
  tls:
  - hosts: [secure.example.com]
    secretName: web-tls
  rules:
  - host: secure.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend: {service: {name: web, port: {number: 80}}}
YAML

# 3. Prove it serves HTTPS (IP = the ingress controller address)
IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.clusterIP}')
curl -sk --resolve secure.example.com:443:$IP https://secure.example.com -o /dev/null -w '%{http_code}\n'
```

**Key Points to Remember:**

- Secret **type must be `kubernetes.io/tls`** with keys `tls.crt` and `tls.key`; `kubectl create secret tls` does exactly that.
- The secret is namespaced: one in `default` referenced from `tls-lab` fails silently.
- Without `ingressClassName` the controller ignores the Ingress unless its class is the cluster default.
- Generate a certificate when the exam does not hand you one:
  `openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout web.key -out web.crt -subj "/CN=secure.example.com"`.

**Official Documentation:**
- https://kubernetes.io/docs/concepts/services-networking/ingress/#tls

---
