#!/usr/bin/env bash
# modules/forkdemo.sh : "forkdemo" command - how a shell really runs programs
#
# Shows, with real process IDs: fork, exec, wait, pipe, zombie, signal.
# In bash, ( ... ) forks a child process, '&' runs it in the background,
# 'exec' replaces the program, 'wait' collects the child's exit status.

cmd_forkdemo() {
    local pid st

    title "POSIX PROCESS LIFECYCLE DEMO (FORK / EXEC / WAIT / IPC)"

    echo
    echo "  ${CYN}${BLD}[Step 1/7] Process Identity:${RST}"
    echo "   Current Shell PID = ${GRN}$$${RST}  │  Parent Process PID (PPID) = ${PUR}$PPID${RST}"

    echo
    echo "  ${CYN}${BLD}[Step 2/7] fork() Process Cloning:${RST}"
    ( echo "   Child Process spawned: PID = ${GRN}$BASHPID${RST}, Parent PID = ${PUR}$$${RST}" )
    note "fork() creates an exact memory replica. Parent receives Child PID; Child receives 0."

    echo
    echo "  ${CYN}${BLD}[Step 3/7] exec() Image Replacement:${RST}"
    (
        echo "   Before exec(): PID = ${GRN}$BASHPID${RST} (executing current shell script)"
        exec bash -c 'echo "   After  exec(): PID = '$BASHPID' (retained identical PID, swapped executable image)"'
    )
    note "exec() replaces text/data segments without allocating a new PID."

    echo
    echo "  ${CYN}${BLD}[Step 4/7] wait() Child Termination Synchronization:${RST}"
    ( sleep 1; exit 7 ) &
    pid=$!
    echo "   Background Worker started at PID ${GRN}$pid${RST}"
    wait "$pid" 2>/dev/null; st=$?
    echo "   wait() harvested exit status: ${YEL}${BLD}$st${RST} (Non-zero indicates exit code 7)"

    echo
    echo "  ${CYN}${BLD}[Step 5/7] pipe() Kernel IPC Buffer:${RST}"
    { echo "   Writer [PID $BASHPID] transmitted payload through kernel buffer" >&2; echo "RetroOS_IPC_Packet"; } |
    { read -r msg; echo "   Reader [PID $BASHPID] received payload: ${GRN}$msg${RST}"; }
    note "Unidirectional anonymous pipe connected between stdout and stdin."

    echo
    echo "  ${RED}${BLD}[Step 6/7] Zombie Process (State 'Z') Detection:${RST}"
    bash -c 'sleep 0.2 & exec sleep 3' &
    pid=$!
    sleep 1
    echo "   Process Table entry for orphaned child of PID $pid:"
    ps -o pid,ppid,stat,comm --ppid "$pid" 2> /dev/null | awk 'NR==1{print "     "$0} NR>1{gsub(/Z/,"\033[41;1;97m Z \033[0m"); print "     "$0}'
    note "State 'Z' indicates process has terminated but descriptor remains in task_struct."
    kill -9 "$pid" 2> /dev/null; wait "$pid" 2> /dev/null || true

    echo
    echo "  ${CYN}${BLD}[Step 7/7] POSIX Signal Delivery (SIGTERM):${RST}"
    sleep 30 &
    pid=$!
    echo "   Spawned PID ${GRN}$pid${RST}, dispatching SIGTERM (Signal 15)..."
    kill -TERM "$pid" 2>/dev/null; wait "$pid" 2>/dev/null; st=$?
    echo "   Process terminated with signal exit code: ${YEL}${BLD}$st${RST} (128 + 15 = 143)"
    note "Signals provide asynchronous inter-process notification."
    echo
}
