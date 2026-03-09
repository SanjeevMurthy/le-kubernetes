# CKA Practice Test 3 - Failed Questions

---

## Question 1: Configure Sysctl Network Parameters

You are an administrator preparing your environment to deploy a Kubernetes cluster using kubeadm. Adjust the following network parameters on the system to the following values, and make sure your changes persist reboots:

- `net.ipv4.ip_forward = 1`
- `net.bridge.bridge-nf-call-iptables = 1`

**Validation Criteria:**

- `net.ipv4.ip_forward` is set to `1`
- `net.bridge.bridge-nf-call-iptables` is set to `1`

### Solution

**Official Documentation:** [Kubernetes - Container Runtimes Prerequisites](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#prerequisites)

Use `sysctl` to adjust system parameters and make them persistent across reboots:

```bash
# Set the required sysctl parameters and make them persistent
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.conf

# Apply the changes
sysctl -p

# Verify the settings
sysctl net.ipv4.ip_forward
sysctl net.bridge.bridge-nf-call-iptables
```

---

## Question 2: Create NetworkPolicy for Ingress Traffic

We have deployed a new pod called `np-test-1` and a service called `np-test-service`. Incoming connections to this service are not working. Troubleshoot and fix it.

Create a NetworkPolicy by the name `ingress-to-nptest` that allows incoming connections to the service over port `80`.

> [!IMPORTANT]
>
> - Don't delete any current objects deployed
> - Don't alter existing objects!

**Validation Criteria:**

- NetworkPolicy is applied to all sources (incoming traffic from all pods)
- Port is correct (`80`)
- Applied to the correct Pod (`np-test-1`)

### Solution

**Official Documentation:** [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ingress-to-nptest
  namespace: default
spec:
  podSelector:
    matchLabels:
      run: np-test-1
  policyTypes:
    - Ingress
  ingress:
    - ports:
        - protocol: TCP
          port: 80
```

**Why this works:**
| Config | Purpose |
|--------|---------|
| `podSelector` | Selects **np-test-1** pod |
| `policyTypes: Ingress` | Controls inbound traffic |
| `ingress` rule | Explicitly allows TCP traffic on port `80` |
| No `from` block | Allows traffic from **any source** (cluster-wide) |

---

## Question 3: Troubleshoot Deployment Scaling

We have created a new deployment called `nginx-deploy`. Scale the deployment to 3 replicas. Has the number of replicas increased? Troubleshoot and fix the issue.

### Solution

**Official Documentation:** [Kubernetes Components](https://kubernetes.io/docs/concepts/overview/components/)

**Step 1:** Scale the deployment

```bash
kubectl scale deploy nginx-deploy --replicas=3
```

**Step 2:** Check if controller-manager is running

```bash
kubectl get pods -n kube-system
```

**Step 3:** Fix the controller-manager manifest (typo in binary name)

```bash
sed -i 's/kube-contro1ler-manager/kube-controller-manager/g' /etc/kubernetes/manifests/kube-controller-manager.yaml
```

**Step 4:** Verify the fix

```bash
kubectl get deploy
# Expected output:
# NAME           READY   UP-TO-DATE   AVAILABLE   AGE
# nginx-deploy   3/3     3            3           6m2s
```

> [!NOTE]
> **Why `kubectl scale` succeeds but pods don't appear:**
>
> - `kubectl scale` only updates the desired state in etcd via the kube-apiserver
> - The actual creation of Pods is done by the **kube-controller-manager**, which was down

**Mental Model:**
| Component | Role |
|-----------|------|
| **kube-apiserver** | Accepts & stores intent (desired state) |
| **etcd** | Stores that desired state |
| **kube-controller-manager** | Acts on that intent |
| **kubelet** | Runs the Pods |

---

## Question 4: Create HPA with Custom Metrics

Create a Horizontal Pod Autoscaler (HPA) `api-hpa` for the deployment named `api-deployment` located in the `api` namespace.

The HPA should scale the deployment based on a custom metric named `requests_per_second`, targeting an average value of **1000 requests per second** across all pods.

- Minimum replicas: `1`
- Maximum replicas: `20`

> [!NOTE]
> Deployment named `api-deployment` is available in `api` namespace. Ignore errors due to the metric `requests_per_second` not being tracked in `metrics-server`.

### Solution

**Official Documentation:** [HorizontalPodAutoscaler Walkthrough - Autoscaling on custom metrics](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/#autoscaling-on-multiple-metrics-and-custom-metrics)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
  namespace: api
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-deployment
  minReplicas: 1
  maxReplicas: 20
  metrics:
    - type: Pods
      pods:
        metric:
          name: requests_per_second
        target:
          type: AverageValue
          averageValue: "1000"
```

### HPA Metric Types Reference

| Type         | Description                                      | Target Types                  | Example                                     |
| ------------ | ------------------------------------------------ | ----------------------------- | ------------------------------------------- |
| **Resource** | Built-in CPU/memory metrics                      | `Utilization`, `AverageValue` | `cpu`, `memory`                             |
| **Pods**     | Custom per-pod metrics, averaged across all pods | `AverageValue` only           | `packets-per-second`, `requests_per_second` |
| **Object**   | Metrics from other Kubernetes objects            | `Value`, `AverageValue`       | `requests-per-second` on Ingress            |
| **External** | Metrics from external systems                    | `Value`, `AverageValue`       | `queue_messages_ready`                      |

---

## Question 5: Configure HTTPRoute Traffic Splitting

Configure the `web-route` to split traffic between `web-service` and `web-service-v2`. The configuration should ensure that:

- **80%** of the traffic is routed to `web-service`
- **20%** is routed to `web-service-v2`

> [!NOTE]
> `web-gateway`, `web-service`, and `web-service-v2` have already been created and are available on the cluster.

**Validation Criteria:**

- Is the `web-route` deployed as HTTPRoute?
- Is the route configured to gateway `web-gateway`?
- Is the route configured to service `web-service`?

### Solution

**Official Documentation:** [Gateway API - HTTP Traffic Splitting](https://gateway-api.sigs.k8s.io/guides/traffic-splitting/)

Use `backendRefs` with `weight` to split traffic proportionally. Weights are relative — 80:20 means 80% and 20%.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
  namespace: default
spec:
  parentRefs:
    - name: web-gateway
      namespace: default
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: web-service
          port: 80
          weight: 80
        - name: web-service-v2
          port: 80
          weight: 20
```

**Apply with:**

```bash
kubectl apply -f web-route.yaml
```
