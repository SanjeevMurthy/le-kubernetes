# Q40. A service fails its file-descriptor limit: raise it with a drop-in

`fdhog.service` is a packaged unit. Its unit file is `/usr/lib/systemd/system/fdhog.service` and it refuses to start: the application needs a hundred open file descriptors and the unit does not allow that many.

1. Raise the service's open file limit to `65536` and its task limit to `4096`.
2. Do it without editing `/usr/lib/systemd/system/fdhog.service`, because the next package upgrade would overwrite that file.
3. Leave the service running, and make sure the raised limits are still in force after a reboot.

The grader reads `systemctl show`, `systemctl is-active`, the limits of the running process under `/proc`, the drop-in file under `/etc/systemd/system/fdhog.service.d/`, and the vendor unit file, which must still be exactly as it shipped.
