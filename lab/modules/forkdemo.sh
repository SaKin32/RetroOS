#!/usr/bin/env bash
# modules/forkdemo.sh : "forkdemo" command - how a shell really runs programs
#
# Shows, with real process IDs: fork, exec, wait, pipe, zombie, signal.
# In bash, ( ... ) forks a child process, '&' runs it in the background,
# 'exec' replaces the program, 'wait' collects the child's exit status.

cmd_forkdemo() {
    local pid st

    title "FORK / EXEC / WAIT DEMO"

    echo
    echo "${CYN}1) Who am I?${RST}"
    echo "   shell PID = $$      parent PID = $PPID"

    echo
    echo "${CYN}2) fork()  - ( ... ) creates a CHILD copy of the shell${RST}"
    ( echo "   child : my PID = $BASHPID, my parent = $$" )
    note "The child is a copy of the parent with a NEW PID. fork() returns twice:"
    note "the child PID to the parent, and 0 to the child."

    echo
    echo "${CYN}3) exec()  - replace the child with a different program${RST}"
    (
        echo "   before exec: PID = $BASHPID  (running the shell code)"
        exec bash -c 'echo "   after  exec: PID = $$  (SAME PID, new program: bash -c)"'
    )
    note "exec() does not create a process, it swaps the program inside the same one."
    note "So a shell runs a command as:  fork() -> child calls exec() -> parent wait()."

    echo
    echo "${CYN}4) wait()  - the parent collects the child's exit status${RST}"
    ( sleep 1; exit 7 ) &
    pid=$!
    echo "   started child $pid in the background (&), the shell did not block"
    wait "$pid"; st=$?
    echo "   wait() returned: child $pid finished with exit status ${BLD}$st${RST}"
    note "'echo \$?' shows this number. 0 = success, anything else = error."

    echo
    echo "${CYN}5) pipe  - two processes joined by a kernel buffer${RST}"
    { echo "   writer PID = $BASHPID sends: hello" >&2; echo hello; } |
    { read -r msg; echo "   reader PID = $BASHPID received: $msg"; }
    note "Two DIFFERENT PIDs: 'a | b' forks one process per side, connected by pipe()."
    note "The writer's stdout and the reader's stdin are the two ends of the pipe."

    echo
    echo "${CYN}6) zombie  - a finished child that nobody has wait()ed for${RST}"
    bash -c 'sleep 0.2 & exec sleep 3' &       # parent execs 'sleep 3' and never waits
    pid=$!
    sleep 1
    echo "   children of $pid (the child 'sleep 0.2' already finished):"
    ps -o pid,ppid,stat,comm --ppid "$pid" 2> /dev/null | sed 's/^/     /'
    note "STAT 'Z' = zombie: it is dead, but its entry stays in the process table"
    note "until the parent calls wait(). Too many zombies fill the table."
    kill "$pid" 2> /dev/null; wait "$pid" 2> /dev/null

    echo
    echo "${CYN}7) signal  - the kernel tells a process to stop${RST}"
    sleep 30 &
    pid=$!
    echo "   started 'sleep 30' as PID $pid, now sending SIGTERM (15) ..."
    kill -TERM "$pid"; wait "$pid" 2> /dev/null; st=$?
    echo "   exit status = ${BLD}$st${RST}  (128 + signal number 15 = 143)"
    note "Ctrl+C sends SIGINT (2) to the foreground program, not to the shell itself."
    echo
}
