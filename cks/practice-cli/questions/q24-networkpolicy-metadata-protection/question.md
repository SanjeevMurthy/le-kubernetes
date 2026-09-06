# Q24. Block the cloud metadata endpoint

Use context: the cluster you are already on. No node access is needed for this question.

Namespace `metadata-lab` runs a deployment named `app` whose pods carry the label `app=app`. There are no NetworkPolicies in the namespace, so those pods can reach the cloud provider metadata service at `169.254.169.254`, which hands out instance credentials to anything that asks.

1. Create a NetworkPolicy named `metadata-deny` in namespace `metadata-lab`.
2. It must apply to the pods labelled `app=app`, and to those pods only.
3. It must control **egress**.
4. Egress to every other address must keep working. Express this as a single `ipBlock` rule that allows `0.0.0.0/0` and excepts `169.254.169.254/32`.

The `app` pods must stay `Running`, and a pod labelled `app=app` must still be able to resolve DNS after the policy is applied.
