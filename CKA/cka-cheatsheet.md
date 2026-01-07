# CKA Cheat Sheet

## JSONPath & Custom Columns

Mastering `jsonpath` and `custom-columns` is essential for the CKA to quickly filter and format output without relying on `grep`/`awk`.

### 1. Basic Syntax

- **Root**: `$` (often implicit in kubectl)
- **Current Node**: `@`
- **Lists/Arrays**: `[*]` (all items), `[0]` (first item)
- **Filter**: `[?(@.field=="value")]`

### 2. Common One-Liners

**Get all Pod names**

```bash
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
```

**Get all Container images from all Pods**

```bash
kubectl get pods -A -o jsonpath='{.items[*].spec.containers[*].image}'
```

**Get Pod Name and Node Name (formatted)**

```bash
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}{end}'
```

### 3. Filtering

**Select Pods referencing a specific PVC**

```bash
kubectl get pods -o jsonpath='{.items[?(@.spec.volumes[*].persistentVolumeClaim.claimName=="my-pvc")].metadata.name}'
```

**Select Internal IP of a specific Node**

```bash
kubectl get nodes node01 -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'
```

**List only Running Pods**

```bash
kubectl get pods -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}'
```

### 4. Custom Columns

Easier alternative to JSONPath for tabular output.

**Show Pod Name, Image, and Restart Count**

```bash
kubectl get pods -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image,RESTARTS:.status.containerStatuses[0].restartCount
```

**Show Node Name and Taints**

```bash
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints[*].key
```

### 5. Sorting

**Sort Pods by Creation Timestamp (Oldest first)**

```bash
kubectl get pods --sort-by=.metadata.creationTimestamp
```

**Sort PVs by Capacity**

```bash
kubectl get pv --sort-by=.spec.capacity.storage
```

---

### Pro Tips for CKA

1. **Identify the path first**: Use `kubectl get <resource> <name> -o json | less` to navigate the JSON structure and find the exact path.
2. **Use `custom-columns` for complex formatting**: It includes headers automatically and handles spacing better than raw jsonpath with tabs.
3. **Looping**: Always start with `{.items[*]}` when listing resources, but remember that simpler lookups on a single resource don't need the list index.
