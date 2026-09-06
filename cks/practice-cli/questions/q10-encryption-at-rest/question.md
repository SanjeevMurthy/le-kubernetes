# Q10. Encrypt Secrets at Rest (EncryptionConfiguration)

Enable encryption at rest for Secrets using an `aescbc` provider. Configure the API server to use `/etc/kubernetes/enc/enc.yaml`, then ensure all existing Secrets are encrypted. Verify a Secret is stored encrypted in etcd.
