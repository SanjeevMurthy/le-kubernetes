## Kubelet misconfigured or Crashed

1. Where to find kubelet logs

   - `journalctl -u kubelet` (or `journalctl -u kubelet -f` to follow)

2. Where to find kubelet configuration

   - `/var/lib/kubelet/config.yaml`

3. How to find kubelet and kubeadm flags

   - `/var/lib/kubelet/kubeadm-flags.env`

4. How to find kubelet and kubeadm erros from logs, status or journalctl logs

   - Check status: `systemctl status kubelet`
   - Check extended logs: `journalctl -xu kubelet`

5. How to restart kubelet

   - `systemctl daemon-reload && systemctl restart kubelet`

6. How to find kubelet and kubeadm status after restart
   - `systemctl status kubelet`

## Application Misconfigured : Deployment Not Starting

1. Check the configMap name and keys name and Secrets
2. Check the deployment yaml
3. Check if Deployment is waiting for the specific nodename
4. Check for port collisions inside a multi container deployment
5. Check the logs for all containers in the deployment
   `kubectl -n management logs --all-containers deploy/collect-data > /root/logs.log`

## Metric server issues

Failed to scrape node ... tls: failed to verify certificate: x509: cannot validate certificate for <node-ip> because it doesn't contain any IP SANs

🔍 What this means

Your metrics-server is trying to scrape kubelet metrics over HTTPS, but:

The kubelet is using a self-signed certificate

That cert doesn’t include the node IP in SANs
➡️ TLS verification fails, so no metrics are collected → HPA shows <unknown>.

Ensure you have there args:

```yaml
args:
  - --cert-dir=/tmp
  - --secure-port=4443
  - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
  - --kubelet-insecure-tls
```
