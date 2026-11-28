#!/usr/bin/env bash
# =====================================================================
#  RetroOS Shell  (bash edition)
#
#  Run it with:        bash retroos.sh
#  One command only:   bash retroos.sh -c "sched rr 2 0:5 1:3 2:8"
#
#  How it works (the main loop of every shell):
#     1. show the prompt       2. read a line       3. run it       4. repeat
#  Pipes, redirects, & && || ; $(...) and variables are done by bash itself.
#  Our own commands (sched, memory, pcb, race ...) are shell FUNCTIONS
#  that live in lab/modules, so they also work inside pipes.
# =====================================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB="$DIR/lab"

# ---------- load libraries and modules ----------
source "$LAB/lib/ui.sh"          # colours, title/note, ask_int, locks
source "$LAB/lib/theme.sh"       # themes, prompt, banner
source "$LAB/lib/banner.sh"      # purple cat welcome screen
for _m in sched deadlock bankers pcb memory sysinfo forkdemo demo; do
    source "$LAB/modules/$_m.sh"
done
unset _m

# ---------- user name ----------
USERFILE="$HOME/.retroos_user"
if [[ -r $USERFILE ]]; then read -r RS_USER < "$USERFILE"; fi
RS_USER=${RS_USER:-${USER:-user}}
LAST=0                           # exit status of the last command (shown in the prompt)
set_theme "$THEME"

# ---------- commands of RetroOS (functions, so pipes work with them) ----------
sched()        { cmd_sched "$@"; }
race()         { demo_race; }
deadlock()     { demo_deadlock; }
bankers()      { demo_bankers; }
pcb()          { cmd_pcb "$@"; }
memory()       { cmd_memory "$@"; }
meminfo()      { cmd_meminfo; }
kinfo()        { cmd_kinfo; }
monitor()      { cmd_monitor "$@"; }
trace()        { cmd_trace "$@"; }
forkdemo()     { cmd_forkdemo; }
demo()         { cmd_demo; }
sysinfo()      { show_banner; }
mode-switch()  { cmd_modeswitch; }
cls()          { printf '\033[H\033[2J\033[3J'; clear 2>/dev/null || true; show_banner; }

theme() {
    if [[ -z $1 ]]; then echo "  themes: cyber retro matrix dracula   (now: $THEME)"; return 0; fi
    if set_theme "$1"; then echo "  ${C_ACC}Theme changed to '$1'.${C_RST}"
    else echo "  unknown theme '$1'. Try: cyber retro matrix dracula"; return 1; fi
}

user() {
    if [[ -z $1 ]]; then echo "  user name: $RS_USER"; return 0; fi
    RS_USER=$1; echo "$RS_USER" > "$USERFILE"; echo "  user name is now '$RS_USER'"
}

help() {
    if [[ -n ${1:-} ]]; then
        case $1 in
            sched)
                title "MANUAL: CPU SCHEDULING & GANTT CHARTS (sched)"
                echo "  ${CYN}${BLD}SYNOPSIS:${RST} sched <fcfs|sjf|prio|rr|compare> [args...]"
                echo
                echo "  ${CYN}${BLD}DESCRIPTION:${RST}"
                echo "    Simulates preemptive and non-preemptive CPU dispatching algorithms."
                echo "    Renders an animated graphical Gantt chart and process metrics table."
                echo
                echo "  ${CYN}${BLD}METRICS & FORMULAS:${RST}"
                echo "    • Turnaround Time (TAT) = Completion Time (CT) - Arrival Time (AT)"
                echo "    • Waiting Time (WT)    = Turnaround Time (TAT) - Burst Time (BT)"
                echo
                echo "  ${CYN}${BLD}ALGORITHMS:${RST}"
                echo "    • fcfs               First-Come First-Served (non-preemptive, FIFO order)"
                echo "    • sjf                Shortest Job First (non-preemptive, minimizes WT)"
                echo "    • prio               Priority Scheduling (smaller integer = higher priority)"
                echo "    • rr <q>             Round Robin (preemptive, time quantum slice q)"
                echo "    • compare            Comparative benchmark across all 4 algorithms"
                echo
                echo "  ${CYN}${BLD}TEXTBOOK REFERENCE:${RST} Silberschatz et al. Ch 5 (CPU Scheduling)"
                echo "  ${CYN}${BLD}EXAMPLES:${RST}"
                echo "    sched rr 2 0:5 1:3 2:8"
                echo "    sched compare 0:5:2 1:3:3 2:8:1 3:2:4"
                echo
                return 0 ;;
            bankers)
                title "MANUAL: DIJKSTRA'S BANKER'S ALGORITHM (bankers)"
                echo "  ${CYN}${BLD}SYNOPSIS:${RST} bankers"
                echo
                echo "  ${CYN}${BLD}DESCRIPTION:${RST}"
                echo "    Proactive deadlock avoidance algorithm for multi-resource allocation."
                echo "    Maintains Allocation, Max, Available and Need matrices."
                echo "    Derives Need[i][j] = Max[i][j] - Allocation[i][j]."
                echo
                echo "  ${CYN}${BLD}SAFETY ALGORITHM:${RST}"
                echo "    Finds safe execution sequence where Finish[i] == false and Need[i] <= Work."
                echo "    If all processes complete, system state is SAFE; otherwise UNSAFE."
                echo
                echo "  ${CYN}${BLD}TEXTBOOK REFERENCE:${RST} Silberschatz et al. Ch 8.6.3 (Banker's Algorithm)"
                echo "  ${CYN}${BLD}EXAMPLES:${RST} bankers  (interactive menu with custom matrices)"
                echo
                return 0 ;;
            deadlock)
                title "MANUAL: DEADLOCK DETECTION & MITIGATION (deadlock)"
                echo "  ${CYN}${BLD}SYNOPSIS:${RST} deadlock"
                echo
                echo "  ${CYN}${BLD}DESCRIPTION:${RST}"
                echo "    Simulates concurrency deadlock and validates Coffman's 4 conditions:"
                echo "    Mutual Exclusion, Hold & Wait, No Preemption, Circular Wait."
                echo
                echo "  ${CYN}${BLD}PREVENTION STRATEGIES:${RST}"
                echo "    • Global Lock Ordering: Enforces lock hierarchy (breaks Circular Wait)"
                echo "    • Trylock & Back-off: Releases primary lock on contention (breaks Hold & Wait)"
                echo
                echo "  ${CYN}${BLD}TEXTBOOK REFERENCE:${RST} Silberschatz et al. Ch 8 (Deadlocks)"
                echo
                return 0 ;;
            memory)
                title "MANUAL: DEMAND PAGING & PAGE REPLACEMENT (memory)"
                echo "  ${CYN}${BLD}SYNOPSIS:${RST} memory <fifo|lru|opt|compare|belady> [frames] [pages...]"
                echo
                echo "  ${CYN}${BLD}POLICIES:${RST}"
                echo "    • fifo               First-In, First-Out page replacement"
                echo "    • lru                Least Recently Used (stack algorithm)"
                echo "    • opt                Optimal / Clairvoyant (theoretical upper bound)"
                echo "    • belady             Empirical proof of Belady's Anomaly (FIFO 3 vs 4 frames)"
                echo "    • compare            Comparative hit/fault benchmark across all three policies"
                echo
                echo "  ${CYN}${BLD}TEXTBOOK REFERENCE:${RST} Silberschatz et al. Ch 9.4 (Page Replacement)"
                echo "  ${CYN}${BLD}EXAMPLES:${RST}"
                echo "    memory lru 3 7 0 1 2 0 3 0 4 2 3"
                echo "    memory belady"
                echo
                return 0 ;;
            pcb)
                title "MANUAL: PROCESS CONTROL BLOCK & STATE MACHINE (pcb)"
                echo "  ${CYN}${BLD}SYNOPSIS:${RST} pcb [self | <pid> | sim <quantum> <arrival:burst...>]"
                echo
                echo "  ${CYN}${BLD}CAPABILITIES:${RST}"
                echo "    • pcb self           Inspects live Linux task_struct of the RetroOS shell"
                echo "    • pcb <pid>          Extracts VmSize, VmRSS, State, and Context Switches"
                echo "    • pcb sim            Tick-by-tick discrete queue lifecycle simulation"
                echo
                echo "  ${CYN}${BLD}TEXTBOOK REFERENCE:${RST} Silberschatz et al. Ch 3.1 (Process State & PCB)"
                echo
                return 0 ;;
            forkdemo)
                title "MANUAL: POSIX PROCESS LIFECYCLE (forkdemo)"
                echo "  ${CYN}${BLD}SYNOPSIS:${RST} forkdemo"
                echo
                echo "  ${CYN}${BLD}DESCRIPTION:${RST}"
                echo "    7-step live demonstration of POSIX process subsystem primitives:"
                echo "    1) PID/PPID  2) fork()  3) exec()  4) wait()  5) pipe()  6) zombie (Z)  7) signals"
                echo
                echo "  ${CYN}${BLD}TEXTBOOK REFERENCE:${RST} Silberschatz et al. Ch 3.3 (Process Operations)"
                echo
                return 0 ;;
            *)
                echo "  ${YEL}No dedicated manual page for '$1'. Showing full command index:${RST}" ;;
        esac
    fi

    local -a rows=(
        "TOPIC 1 : CORE SHELL UTILITIES & POSIX ENVIRONMENT"
        "01. cd <directory>^Change the current working directory"
        "02. ls -la^List files and directories with detailed permissions"
        "03. pwd^Print absolute path of working directory"
        "04. history^Display session command history buffer"
        "05. jobs^List active background jobs and worker PIDs"
        "06. kill <pid>^Send termination signal to a background process"
        "07. cmd1 | cmd2^Pipe standard output of cmd1 to input of cmd2"
        "08. cmd > file^Redirect standard output to file (overwrite)"
        "09. alias <name>=<cmd>^Create custom command shortcut alias"
        "10. cls^Clear screen and terminal scrollback buffer"
        "11. theme <name>^Switch theme: cyber | retro | matrix | dracula"
        "12. user <name>^Set custom terminal user identifier"
        "13. help [cmd]^Display complete reference manual or topic documentation"
        "14. exit^Terminate current RetroOS shell session"
        "TOPIC 2 : CPU SCHEDULING ALGORITHMS & GANTT CHARTS"
        "15. sched fcfs 0:5 1:3 2:8^First-Come, First-Served non-preemptive scheduling"
        "16. sched sjf 0:5 1:3 2:8^Shortest Job First scheduling (minimizes waiting time)"
        "17. sched prio 0:5:1 1:3:2^Priority scheduling (smaller integer = higher priority)"
        "18. sched rr 2 0:5 1:3 2:8^Round Robin time-sliced scheduling with Quantum = 2"
        "19. sched compare 0:5 1:3 2:8^Benchmark all 4 algorithms side-by-side with metrics"
        "TOPIC 3 : PROCESS CONTROL BLOCK (PCB) & LIFECYCLE"
        "20. pcb self^Inspect real task_struct PCB of current shell (/proc)"
        "21. pcb <pid>^Inspect live process control block of any target PID"
        "22. pcb sim 2 0:5 1:3^Tick-by-tick animated process state machine simulation"
        "23. forkdemo^Live telemetry of fork, exec, wait, pipe & zombie (Z)"
        "TOPIC 4 : DEADLOCK DETECTION & AVOIDANCE"
        "24. deadlock^Coffman conditions, wait-for cycle & lock ordering"
        "25. bankers^Dijkstra's Banker's algorithm safe sequence & requests"
        "TOPIC 5 : VIRTUAL MEMORY & PAGE REPLACEMENT"
        "26. memory fifo 3 7 0 1 2 0 3^First-In, First-Out page replacement simulation"
        "27. memory lru 3 7 0 1 2 0 3^Least Recently Used page replacement simulation"
        "28. memory opt 3 7 0 1 2 0 3^Optimal clairvoyant page replacement simulation"
        "29. memory compare 3 7 0 1 2^Benchmark FIFO vs LRU vs OPT hit and fault ratios"
        "30. memory belady^Empirical proof of Belady's Anomaly in FIFO paging"
        "TOPIC 6 : KERNEL INTERNALS & SYSTEM TELEMETRY"
        "31. kinfo^Kernel version, CPU cores, uptime & privilege mode"
        "32. meminfo^Physical RAM usage, buffers & swap memory from /proc"
        "33. monitor 10^Live dynamic in-place CPU and RAM telemetry dashboard"
        "34. mode-switch^Simulate Ring 3 (User) <-> Ring 0 (Kernel) privilege trap"
        "35. trace ls^Trace program system calls in real-time (strace)"
        "TOPIC 7 : AUTOMATED LABORATORY DEMONSTRATION"
        "36. demo^Comprehensive end-to-end automated lab demonstration"
    )
    echo
    echo "${PUR}${BLD}  ┌──────────────────────────────────────────────────────────────────────────────────┐${RST}"
    echo "${CYN}${BLD}  │            RetroOS Shell - Operating Systems Command Index                       │${RST}"
    echo "${PUR}${BLD}  └──────────────────────────────────────────────────────────────────────────────────┘${RST}"
    local r
    for r in "${rows[@]}"; do
        if [[ $r != *"^"* ]]; then
            echo
            echo "  ${CYN}${BLD}▶ [${r%% :*}]${WHT} :${r#* :}${RST}"
            echo "  ${DIM}──────────────────────────────────────────────────────────────────────────────────${RST}"
        else
            local cmd="${r%%^*}" desc="${r#*^}"
            printf "   ${GRN}${BLD}%-37s${RST} ${WHT}%s${RST}\n" "$cmd" "$desc"
        fi
    done
    echo
    note "Type 'help <command>' (e.g. 'help sched' or 'help bankers') for in-depth textbook manuals."
    echo
}

# bash calls this for an unknown command: our own friendly error
command_not_found_handle() {
    echo "${C_ERR}retroos: $1: command not found${C_RST}  ${C_DIM}(type 'help')${C_RST}" >&2
    return 127
}

# ---------- run one line: check syntax, ask for more lines if unfinished ----------
# sets REPLY_LINE to the (possibly extended) line; returns 1 if it is not runnable
_complete_line() {
    local line=$1 err more
    while true; do
        if err=$(bash -n <<< "$line" 2>&1); then REPLY_LINE=$line; return 0; fi
        if [[ $err == *"unexpected end of file"* || $err == *"unexpected EOF"* ]]; then
            if [[ -t 0 ]]; then
                read -e -r -p "${C_DIM}> ${C_RST}" more || return 1
                line+=$'\n'"$more"
            else
                echo "${C_ERR}retroos: incomplete command${C_RST}" >&2; return 1
            fi
        else
            echo "${C_ERR}retroos: syntax error${C_RST} ${C_DIM}(${err##*: })${C_RST}" >&2
            LAST=2; return 1
        fi
    done
}

run_line() {
    local line=$1
    [[ -z ${line//[[:space:]]/} ]] && return 0
    _complete_line "$line" || return 0
    eval "$REPLY_LINE"
    LAST=$?
}

# ---------- start-up ----------
shopt -s expand_aliases          # so that 'alias ll="ls -l"' works inside the shell

if [[ $1 == -c ]]; then          # one-shot mode: bash retroos.sh -c "command"
    run_line "$2"
    exit $LAST
fi

if [[ ! -t 0 ]]; then            # commands come from a pipe or a file
    while IFS= read -r line; do run_line "$line"; done
    exit $LAST
fi

# ---------- interactive shell ----------
HISTFILE="$HOME/.retroos_history"
HISTSIZE=1000
set -o history
history -r 2> /dev/null
set -m                           # job control: jobs, fg, bg, kill %1
trap 'echo' INT                  # Ctrl+C stops the running program, not the shell
trap 'history -w' EXIT           # save the history when we leave

# Zoom in/out or resize the window: text already printed cannot be re-laid-out by the terminal,
# so while the welcome banner is still the only thing on screen we simply draw it again
# (compact version for a narrow window, full cat for a wide one).
BANNER_FRESH=1
_DRAWING_BANNER=0
_on_resize() {
    (( BANNER_FRESH )) || return 0
    (( _DRAWING_BANNER )) && return 0
    _DRAWING_BANNER=1
    printf '\033[H\033[2J\033[3J'   # wipe screen AND scrollback, so old copies do not pile up
    show_banner
    printf '%s' "$PROMPT"
    _DRAWING_BANNER=0
}
trap '_on_resize' WINCH

# Clear screen and entire terminal scrollback buffer so RetroOS starts completely clean
printf '\033[H\033[2J\033[3J'
clear 2> /dev/null || true

cd "$HOME" || true
_DRAWING_BANNER=1
show_banner
_DRAWING_BANNER=0

while true; do                   # ===== the main loop =====
    make_prompt
    read -e -r -p "$PROMPT" line
    rc=$?
    if (( rc > 128 )); then echo; continue; fi         # Ctrl+C at the prompt
    if (( rc != 0 )); then echo; echo "  ${C_DIM}bye!${C_RST}"; break; fi   # Ctrl+D
    [[ -z ${line//[[:space:]]/} ]] && continue
    history -s "$line"
    BANNER_FRESH=0               # something else is on screen now: do not redraw the banner
    run_line "$line"
done

