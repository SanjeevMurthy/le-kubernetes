# Q3. Ingress TLS Termination (solution)

**Concept & Explanation:**

TLS termination at the Ingress means the controller decrypts HTTPS using a certificate/key supplied as a `kubernetes.io/tls` secret, referenced under `spec.tls`. You generate the cert with openssl, load it into a TLS secret, and bind it to the host in the Ingress.

**Solution — Step by Step:**

```bash
# 1. Self-signed cert/key for the host
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt -subj "/CN=secure.example.com/O=secure"

# 2. TLS secret
kubectl create secret tls web-tls --cert=tls.crt --key=tls.key -n prod

# 3. Ingress with TLS
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata: {name: web-ingress, namespace: prod}
spec:
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
EOF
```

**Key Points to Remember:**

- Secret **type must be `kubernetes.io/tls`** with keys `tls.crt` and `tls.key` — `create secret tls` does this.
- `spec.tls[].secretName` binds the cert to the host(s) in `spec.tls[].hosts`.
- Verify: `kubectl get ingress -n prod` shows the host; `curl -k https://secure.example.com --resolve ...`.

**Official Documentation:**
- https://kubernetes.io/docs/concepts/services-networking/ingress/#tls

---
