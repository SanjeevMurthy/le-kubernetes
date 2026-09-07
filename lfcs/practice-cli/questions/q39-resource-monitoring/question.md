# Q39. Report CPU hog, load, cores, memory and process count

Something on this host is burning CPU and the capacity team wants five numbers. Write each one to its own file under `/opt/course/39` (`$COURSE_DIR/39` on this lab). Each file holds the bare value with no label around it.

1. `cpu.txt`: the PID of the process using the most CPU right now.
2. `cores.txt`: the number of CPU cores this host has.
3. `load.txt`: the load averages over 1, 5 and 15 minutes, on one line separated by spaces.
4. `mem.txt`: the available memory in MiB, as `free -m` reports available memory.
5. `procs.txt`: the total number of processes running on the host.

The grader reads each file, finds the busy process itself, and compares. Memory and the process count move between the moment the answer is written and the moment it is read, so those two are accepted within a margin. The PID and the core count are not.
