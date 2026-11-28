#!/usr/bin/env bash
# modules/demo.sh : "demo" command - shows every feature in one go.
# Press Enter between parts (the pauses are skipped if input is not a terminal).

_demo_pause() {
    [[ -t 0 ]] || return 0
    read -r -p "${DIM}  -- press Enter for the next part --${RST}" _
}

# _demo_run "command"  -> show the command, then run it through the shell
_demo_run() {
    echo
    echo "${YEL}${BLD}${RS_USER}@retros ${ARROW}${RST} $1"
    eval "$1"
}

cmd_demo() {
    title "RETROOS DEMO  (part 1/7)  Shell basics"
    _demo_run "ls | grep sh > /tmp/retroos_demo.txt; cat /tmp/retroos_demo.txt"
    _demo_run "echo hello && echo second || echo never"
    _demo_run "sleep 3 &"
    _demo_run "jobs"
    _demo_run "no-such-command"
    _demo_run "x=5; echo x is \$x"
    rm -f /tmp/retroos_demo.txt
    _demo_pause

    title "RETROOS DEMO  (part 2/7)  fork / exec / wait / pipe / zombie"
    cmd_forkdemo
    _demo_pause

    title "RETROOS DEMO  (part 3/7)  CPU scheduling"
    _demo_run "sched rr 2 0:5 1:3 2:8"
    _demo_run "sched compare 0:5:2 1:3:3 2:8:1 3:2:4"
    _demo_pause

    title "RETROOS DEMO  (part 4/7)  Process Control Block"
    _demo_run "pcb sim 2 0:3 1:2 2:4"
    _demo_pause

    title "RETROOS DEMO  (part 5/7)  Memory: page replacement"
    _demo_run "memory compare 3 7 0 1 2 0 3 0 4 2 3 0 3 2"
    _demo_run "memory belady"
    _demo_run "meminfo"
    _demo_pause

    title "RETROOS DEMO  (part 6/7)  Deadlock and Banker's algorithm"
    printf '1\n4\n0\n' | demo_deadlock
    printf '1\n5\n0\n' | demo_bankers
    _demo_pause

    title "RETROOS DEMO  (part 7/7)  Kernel"
    _demo_run "kinfo"
    _demo_run "mode-switch"
    _demo_run "mode-switch"
    echo
    echo "${GRN}${BLD}  Demo finished.${RST}"
}
