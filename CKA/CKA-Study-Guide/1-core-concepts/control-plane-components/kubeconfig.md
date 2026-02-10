# Kubeconfig Guide

**Kubeconfig** is the configuration file used by `kubectl` and other Kubernetes tools to locate and authenticate to Kubernetes clusters. It defines clusters, users, and contexts that allow you to switch between different environments seamlessly.

## File Location

By default, `kubectl` looks for the kubeconfig file at:

```bash
~/.kube/config
```

You can override this using:

- **Environment variable**: `KUBECONFIG=/path/to/config`
- **Command-line flag**: `kubectl --kubeconfig=/path/to/config`

## Kubeconfig Structure

A kubeconfig file has three main sections: **clusters**, **users**, and **contexts**.

```yaml
apiVersion: v1
kind: Config
preferences: {}

# 1. CLUSTERS - Define cluster connection details
clusters:
  - cluster:
      certificate-authority-data: LS0tLS1CRUd... # Base64-encoded CA cert
      # OR use a file path:
      # certificate-authority: /path/to/ca.crt
      server: https://192.168.1.10:6443
    name: production-cluster
  - cluster:
      server: https://10.0.0.5:6443
      certificate-authority: /etc/kubernetes/pki/ca.crt
    name: staging-cluster

# 2. USERS - Define authentication credentials
users:
  - name: admin-user
    user:
      client-certificate-data: LS0tLS1CRUd... # Base64-encoded client cert
      client-key-data: LS0tLS1CRUd... # Base64-encoded client key
  - name: developer
    user:
      token: eyJhbGciOiJSUzI1NiIs... # Bearer token

# 3. CONTEXTS - Map users to clusters with optional namespace
contexts:
  - context:
      cluster: production-cluster
      user: admin-user
      namespace: default
    name: prod-admin
  - context:
      cluster: staging-cluster
      user: developer
      namespace: dev
    name: staging-dev

# 4. CURRENT-CONTEXT - The active context
current-context: prod-admin
```

### Key Components Explained

| Component           | Description                                                        |
| :------------------ | :----------------------------------------------------------------- |
| **clusters**        | API server addresses and CA certificates for each cluster          |
| **users**           | Authentication credentials (certs, tokens, exec plugins)           |
| **contexts**        | Combines a cluster + user + optional namespace into a named config |
| **current-context** | The currently active context used by `kubectl`                     |

## Essential kubectl config Commands

### Viewing Configuration

```bash
# View entire kubeconfig (merged if multiple files)
kubectl config view

# View kubeconfig with secrets/certificates (not redacted)
kubectl config view --raw

# View the current context
kubectl config current-context

# List all available contexts
kubectl config get-contexts

# List all clusters defined
kubectl config get-clusters

# List all users defined
kubectl config get-users
```

### Switching Contexts

```bash
# Switch to a different context
kubectl config use-context staging-dev

# Run a command with a specific context (without switching)
kubectl --context=prod-admin get pods
```

### Setting and Modifying Configuration

```bash
# Set a cluster entry
kubectl config set-cluster my-cluster \
  --server=https://192.168.1.100:6443 \
  --certificate-authority=/path/to/ca.crt

# Set a user entry with client certificates
kubectl config set-credentials my-user \
  --client-certificate=/path/to/client.crt \
  --client-key=/path/to/client.key

# Set a user entry with token
kubectl config set-credentials my-user --token=my-bearer-token

# Create a new context
kubectl config set-context my-context \
  --cluster=my-cluster \
  --user=my-user \
  --namespace=my-namespace

# Set default namespace for a context
kubectl config set-context --current --namespace=kube-system
```

### Deleting Configuration

```bash
# Delete a context
kubectl config delete-context staging-dev

# Delete a cluster entry
kubectl config delete-cluster staging-cluster

# Delete a user entry
kubectl config delete-user developer

# Unset a specific property
kubectl config unset users.my-user
```

## Reading Information from Kubeconfig

### Using JSONPath & Go Templates

```bash
# Get the current context name
kubectl config view -o jsonpath='{.current-context}'

# Get the server URL for current context
kubectl config view -o jsonpath='{.clusters[?(@.name=="production-cluster")].cluster.server}'

# Get all cluster names
kubectl config view -o jsonpath='{.clusters[*].name}'

# Get context names with their clusters
kubectl config view -o jsonpath='{range .contexts[*]}{.name}{"\t"}{.context.cluster}{"\n"}{end}'

# Get the namespace for current context
kubectl config view -o jsonpath='{.contexts[?(@.name=="prod-admin")].context.namespace}'
```

### Extracting Certificates

```bash
# Extract and decode the CA certificate
kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ca.crt

# Extract and decode the client certificate
kubectl config view --raw -o jsonpath='{.users[0].user.client-certificate-data}' | base64 -d > client.crt

# Extract and decode the client key
kubectl config view --raw -o jsonpath='{.users[0].user.client-key-data}' | base64 -d > client.key

# Verify the extracted certificate
openssl x509 -in client.crt -text -noout
```

## Multiple Kubeconfig Files

You can merge multiple kubeconfig files using the `KUBECONFIG` environment variable:

```bash
# Merge multiple config files
export KUBECONFIG=~/.kube/config:~/.kube/config-staging:~/.kube/config-prod

# View merged configuration
kubectl config view

# Flatten and save merged config to a single file
kubectl config view --flatten > ~/.kube/merged-config
```

> [!IMPORTANT]
> When multiple files are merged, contexts, clusters, and users with the same name will use the first occurrence found (left to right in the KUBECONFIG path).

## Authentication Methods

Kubeconfig supports multiple authentication mechanisms:

### 1. Client Certificates (X.509)

```yaml
users:
  - name: cert-user
    user:
      client-certificate: /path/to/client.crt
      client-key: /path/to/client.key
      # OR inline (base64-encoded):
      # client-certificate-data: LS0t...
      # client-key-data: LS0t...
```

### 2. Bearer Token

```yaml
users:
  - name: token-user
    user:
      token: eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 3. Exec Plugin (e.g., for cloud providers)

```yaml
users:
  - name: gcp-user
    user:
      exec:
        apiVersion: client.authentication.k8s.io/v1beta1
        command: gke-gcloud-auth-plugin
        interactiveMode: IfAvailable
        provideClusterInfo: true
```

Common exec plugins:

- **AWS**: `aws eks get-token` or `aws-iam-authenticator`
- **GCP**: `gke-gcloud-auth-plugin`
- **Azure**: `kubelogin`

## System Kubeconfig Files

On Kubernetes nodes managed by `kubeadm`, several predefined kubeconfig files exist:

| File                                      | User Identity                    | Purpose                             |
| :---------------------------------------- | :------------------------------- | :---------------------------------- |
| `/etc/kubernetes/admin.conf`              | `kubernetes-admin`               | Cluster administrator (full access) |
| `/etc/kubernetes/kubelet.conf`            | `system:node:<node-name>`        | Kubelet to API server auth          |
| `/etc/kubernetes/controller-manager.conf` | `system:kube-controller-manager` | Controller manager auth             |
| `/etc/kubernetes/scheduler.conf`          | `system:kube-scheduler`          | Scheduler auth                      |

```bash
# Use admin.conf for kubectl on control-plane node
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl get nodes

# Or copy to user's home directory
mkdir -p ~/.kube
cp /etc/kubernetes/admin.conf ~/.kube/config
chown $(id -u):$(id -g) ~/.kube/config
```

## Troubleshooting

### Common Issues

1. **"Unable to connect to the server"**

   ```bash
   # Check if the server address is reachable
   kubectl config view -o jsonpath='{.clusters[0].cluster.server}'
   curl -k https://<api-server>:6443/healthz
   ```

2. **"x509: certificate signed by unknown authority"**
   - The CA certificate in kubeconfig doesn't match the server's CA.
   - Verify and update `certificate-authority-data` or `certificate-authority` path.

3. **"Unauthorized" or "Forbidden"**

   ```bash
   # Check what user/token is being used
   kubectl auth whoami

   # Check RBAC permissions
   kubectl auth can-i get pods --as=system:serviceaccount:default:my-sa
   ```

4. **"error: no context exists with the name"**
   ```bash
   # List available contexts
   kubectl config get-contexts
   ```

### Validation Commands

```bash
# Test cluster connectivity
kubectl cluster-info

# Verify current identity
kubectl auth whoami

# Check API server health
kubectl get --raw /healthz

# Dry-run to validate config without executing
kubectl config view --minify
```

## Verification

To ensure your kubeconfig is properly set up:

1. **Check Current Context**:

   ```bash
   kubectl config current-context
   ```

2. **Verify Cluster Connection**:

   ```bash
   kubectl cluster-info
   ```

   Output should show the Kubernetes control plane address.

3. **Validate Permissions**:

   ```bash
   kubectl auth can-i '*' '*'
   ```

4. **List Resources**:
   ```bash
   kubectl get nodes
   kubectl get namespaces
   ```
   If these return data, your kubeconfig is working correctly.
