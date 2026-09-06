# Q16. Detect Threats with Falco Rules

Falco is running on the node. Add a custom rule that fires at `WARNING` when a shell (`bash`/`sh`) is started inside any container, with an output line that includes the container name and process. Reload Falco without a full restart and confirm the rule triggers.
