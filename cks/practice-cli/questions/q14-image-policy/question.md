# Q14. Restrict Images via ImagePolicyWebhook/Registry

Only images from the registry `registry.internal` may run cluster-wide. Implement this with admission control. (Either configure the `ImagePolicyWebhook` admission plugin against the provided endpoint, or enforce it with a Kyverno policy if a webhook backend is unavailable.)
