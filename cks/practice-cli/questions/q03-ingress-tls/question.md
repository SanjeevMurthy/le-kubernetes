# Q3. Ingress TLS Termination

Namespace `tls-lab` runs deployment `web` behind service `web` on port 80. A self-signed certificate and its private key for host `secure.example.com` are already on disk at `/opt/course/3/web.crt` and `/opt/course/3/web.key` (the setup output prints the exact directory used on this host).

1. Create a secret named `web-tls` in namespace `tls-lab`, of type `kubernetes.io/tls`, from that certificate and key.
2. Create an Ingress named `web-ingress` in `tls-lab`, on ingress class `nginx`, that routes host `secure.example.com` to service `web` on port 80 and terminates TLS using the `web-tls` secret.
3. Confirm that an HTTPS request for `https://secure.example.com`, resolved to the ingress controller, returns HTTP 200.
