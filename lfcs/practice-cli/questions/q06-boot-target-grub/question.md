# Q06. Default target and GRUB timeout, persistent

Somebody left this server booting into a graphical session with a boot menu that flashes past too quickly to use.

1. Make the host boot into `multi-user.target` by default, permanently. Do not reboot.
2. Set the GRUB menu timeout to 10 seconds, and make the boot loader actually use that value.

Do not edit the generated `grub.cfg`. The grader reads `systemctl get-default`, `/etc/default/grub`, and the generated boot configuration under `/boot`.
