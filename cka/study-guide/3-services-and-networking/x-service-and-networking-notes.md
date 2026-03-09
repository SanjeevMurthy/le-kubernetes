# CoreDNS Corefile Explanation

The `Corefile` defines how CoreDNS handles DNS queries within a Kubernetes cluster. It is composed of a chain of plugins that process requests in order.

Below is a breakdown of the standard and custom sections found in a typical CKA exam or production `Corefile`.

## 1. The Server Block

- **`.:53 { ... }`**: This defines the "Zone" and "Port". The `.` indicates that this block handles **root** level queries (i.e., _all_ DNS queries for any domain). It listens on port **53**.

## 2. Standard Plugins (Logging & Health)

- **`log`**: Enables query logging. Every DNS query received will be logged to the pod's standard output (viewable via `kubectl logs`).
- **`errors`**: Logs any errors encountered during query processing to standard output.
- **`health`**: Serves a health check endpoint (usually on port 8080).
  - `lameduck 5s`: Allows the process to shut down gracefully, continuing to serve requests for 5 seconds after receiving a termination signal.
- **`ready`**: Serves a readiness probe endpoint (usually on port 8181). This tells Kubernetes when the pod is ready to accept traffic.
- **`prometheus :9153`**: Exposes standard CoreDNS metrics in Prometheus format on port 9153.

## 3. Custom Rules (Scenario Specific)

- **`rewrite name suffix cka.example.com cluster.local`**:
  - This is a **custom modification**.
  - It tells CoreDNS: "If you receive a query ending in `cka.example.com`, pretend it actually ends in `cluster.local`."
  - _Example:_ A query for `my-svc.default.cka.example.com` is rewritten to `my-svc.default.cluster.local` before being processed by the Kubernetes plugin.
- **`hosts { ... }`**:
  - Acts like a `/etc/hosts` file for the cluster.
  - **`10.0.5.20 service.internal.corp`**: This manually maps the domain `service.internal.corp` to the IP `10.0.5.20`.
  - **`fallthrough`**: Crucial. Without this, if a user queried a domain _not_ in this block, CoreDNS might stop here. `fallthrough` tells it to pass unmatched queries to the next plugin.

## 4. Kubernetes Resolution

- **`kubernetes cluster.local ... { ... }`**: This is the core plugin that resolves Kubernetes Service and Pod names.
  - `cluster.local`: The domain suffix it answers for.
  - `pods insecure`: Allows resolving pod IP addresses via DNS (e.g., `1-2-3-4.default.pod.cluster.local`).
  - `fallthrough ...`: If the query ends in `cluster.local` but the record isn't found (e.g., a typo), pass it down the chain instead of immediately returning "Not Found" (NXDOMAIN).
  - `ttl 30`: Sets the Time-To-Live for successful responses to 30 seconds.

## 5. Upstream / External Resolution

- **`forward . /etc/resolv.conf { ... }`**:
  - This handles **everything else** (like `google.com`).
  - It forwards queries to the nameservers listed in the worker node's `/etc/resolv.conf`.
  - `max_concurrent 1000`: A performance tuning setting.

## 6. Caching & Networking

- **`cache 30 { ... }`**: Caches DNS records for 30 seconds to improve performance.
  - `disable ...`: Specific disable rules for the `cluster.local` domain, likely to ensure internal Kubernetes changes (like a Service IP changing) are picked up immediately without being stale in the cache.
- **`loop`**: Detects if CoreDNS has forwarded a query to itself (a forwarding loop) and stops it.
- **`reload`**: Watches the ConfigMap for changes and reloads the configuration automatically without needing a pod restart (though a restart is often cleaner).
- **`loadbalance`**: If a query returns multiple A or AAAA records (IPs), this randomizes the order in the response to provide basic load balancing.
