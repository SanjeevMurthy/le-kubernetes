# Q3. Ingress TLS Termination

Expose service `web` (port 80) in namespace `prod` through an Ingress `web-ingress` for host `secure.example.com`, terminating TLS using a self-signed certificate stored in a `kubernetes.io/tls` secret named `web-tls`.
