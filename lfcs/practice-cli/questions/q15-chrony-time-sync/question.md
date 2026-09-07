# Q15. Time source, NTP serving, timezone

This host has lost its time configuration. Setup has stopped chrony, removed the lab time source from its configuration file and set the timezone to UTC.

Do three things.

1. Make the host take its time from `time.google.com`, polling it quickly at startup. The configuration line the grader expects is `server time.google.com iburst`.

2. Make the host serve time to the lab network `192.168.56.0/24`. Consuming time and serving it are two different settings, and only one of them is on by default.

3. Set the timezone to `Asia/Kolkata`.

Then start chrony and make sure it comes back at the next boot.

The grader checks the running daemon with `chronyc`, the timezone with `timedatectl show -p Timezone --value`, and the chrony configuration file for both directives. The configuration file is `/etc/chrony/chrony.conf` on Ubuntu and `/etc/chrony.conf` on Rocky, and the service is named `chrony` on Ubuntu and `chronyd` on Rocky. Setup prints which one applies here.

`date -s` is not an answer to any part of this. A running time daemon steps the clock back.
