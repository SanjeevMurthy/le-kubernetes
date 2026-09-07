# Q43. Group collaboration directory with ACLs

`/srv/projects` is the development team's directory and `/srv/projects/alpha` is one project inside it. The accounts and groups already exist: `ana` is in the group `devs`, and `qauser` is in the group `qa`.

1. `/srv/projects` must belong to the group `devs`, and the owner and that group must have full access while every other account gets nothing through the mode bits. Files created inside it must inherit the group `devs`.
2. The group `qa` must be able to read and traverse `/srv/projects` itself, and must automatically get read and traverse access to everything created inside it from now on. `qa` must never get write access.
3. `ana` must have full access to the existing directory `/srv/projects/alpha`, which the mode bits alone do not give her.
4. The ACL mask must not reduce any of the permissions granted above. An entry that grants `r-x` and takes effect as `r--` is wrong.

The grader reads `stat` and `getfacl -p`, works out the effective permission of each named entry after the mask, and then creates a file inside `/srv/projects` as root and checks that `qauser` can read it and that the file's group is `devs`.
