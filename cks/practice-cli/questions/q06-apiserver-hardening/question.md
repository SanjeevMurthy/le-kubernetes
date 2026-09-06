# Q6. Restrict the API Server (apiserver flags)

Harden the API server on the control-plane node: disable anonymous authentication, ensure the authorization mode is `Node,RBAC`, and enable the `NodeRestriction` admission plugin. Confirm the API server comes back healthy.
