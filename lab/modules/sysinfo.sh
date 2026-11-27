#!/usr/bin/env bash
# modules/sysinfo.sh : kernel and memory information
#
#   kinfo          what the kernel tells us (version, uptime, processes ...)
#   meminfo        RAM usage from /proc/meminfo
#   monitor [n]    live CPU and RAM bars, n refreshes (default 5)
#   mode-switch    toggle a SIMULATED privilege level (Ring 3 user <-> Ring 0 kernel)
#   trace <cmd>    show the system calls a program makes (needs strace)

KERNEL_MODE=0

# _bar PERCENT -> a 20 character bar with gradient colors
_bar() {
    local pct=$1 i out="" full=$(( $1 * 20 / 100 ))
    local col=$GRN
    (( pct > 50 )) && col=$YEL
    (( pct > 80 )) && col=$RED
    for (( i = 0; i < 20; i++ )); do
        if (( i < full )); then out+="${col}#${RST}"; else out+="${DIM}-${RST}"; fi
    done
    echo "[$out]"
}

# _mem_kb KEY -> value in kB from /proc/meminfo
_mem_kb() { awk -v k="$1:" '$1 == k {print $2}' /proc/meminfo; }

cmd_meminfo() {
    local total free avail used pct swt swf
    total=$(_mem_kb MemTotal); free=$(_mem_kb MemFree); avail=$(_mem_kb MemAvailable)
    swt=$(_mem_kb SwapTotal);  swf=$(_mem_kb SwapFree)
    used=$(( total - avail )); pct=$(( used * 100 / total ))
    title "VIRTUAL MEMORY TELEMETRY (/proc/meminfo)"
    echo "  ┌────────────────────────────────┬──────────────────────────────┐"
    printf "  │ ${CYN}%-30s${RST} │ ${WHT}%10s MB${RST}                 │\n" "Total Physical RAM" "$(( total / 1024 ))"
    printf "  │ ${CYN}%-30s${RST} │ ${GRN}%10s MB${RST}                 │\n" "Currently Used" "$(( used / 1024 ))"
    printf "  │ ${CYN}%-30s${RST} │ ${CYN}%10s MB${RST}                 │\n" "Available for Allocation" "$(( avail / 1024 ))"
    printf "  │ ${CYN}%-30s${RST} │ ${DIM}%10s MB${RST}                 │\n" "Completely Free" "$(( free / 1024 ))"
    printf "  │ ${CYN}%-30s${RST} │ ${PUR}%10s MB${RST} of %s MB       │\n" "Swap Space" "$(( (swt - swf) / 1024 ))" "$(( swt / 1024 ))"
    echo "  └────────────────────────────────┴──────────────────────────────┘"
    echo
    echo "  RAM Utilization: $(_bar $pct) ${BLD}${pct}%${RST}"
    note "Available memory includes page buffers reclaimed by kernel on-demand."
}

cmd_kinfo() {
    local up days hrs mins procs ctxt btime cpus load
    up=$(awk '{print int($1)}' /proc/uptime)
    days=$(( up / 86400 )); hrs=$(( up % 86400 / 3600 )); mins=$(( up % 3600 / 60 ))
    procs=$(ls /proc | grep -c '^[0-9][0-9]*$')
    ctxt=$(awk '$1 == "ctxt" {print $2}' /proc/stat)
    btime=$(awk '$1 == "btime" {print $2}' /proc/stat)
    cpus=$(nproc 2> /dev/null || grep -c ^processor /proc/cpuinfo)
    load=$(cut -d' ' -f1-3 /proc/loadavg)
    title "KERNEL ARCHITECTURE & TELEMETRY (/proc)"
    echo "  ┌────────────────────────────────┬──────────────────────────────┐"
    printf "  │ ${CYN}%-30s${RST} │ ${WHT}%-28s${RST} │\n" "Kernel Release" "$(uname -s) $(uname -r)"
    printf "  │ ${CYN}%-30s${RST} │ ${WHT}%-28s${RST} │\n" "Host Architecture" "$(uname -m)"
    printf "  │ ${CYN}%-30s${RST} │ ${WHT}%-28s${RST} │\n" "System Uptime" "${days}d ${hrs}h ${mins}m"
    printf "  │ ${CYN}%-30s${RST} │ ${WHT}%-28s${RST} │\n" "CPU Cores Online" "$cpus cores"
    printf "  │ ${CYN}%-30s${RST} │ ${WHT}%-28s${RST} │\n" "Load Average (1m, 5m, 15m)" "$load"
    printf "  │ ${CYN}%-30s${RST} │ ${WHT}%-28s${RST} │\n" "Active Task Descriptors" "$procs processes"
    printf "  │ ${CYN}%-30s${RST} │ ${WHT}%-28s${RST} │\n" "Total Context Switches" "$ctxt"
    printf "  │ ${CYN}%-30s${RST} │ ${PUR}${BLD}%-28s${RST} │\n" "Simulated CPU Ring" "$( (( KERNEL_MODE )) && echo 'Ring 0 (Kernel Supervisor)' || echo 'Ring 3 (User Unprivileged)')"
    echo "  └────────────────────────────────┴──────────────────────────────┘"
    echo
    echo "  ${CYN}${BLD}Kernel Privilege Trapping Hierarchy:${RST}"
    echo "    ${CYN}User Space (Ring 3)${RST}  ──> Command execution: fork() -> exec()"
    echo "            │"
    echo "            ▼  ${YEL}[Trap via System Call: int 0x80 / syscall]${RST}"
    echo "    ${PUR}Kernel Space (Ring 0)${RST} ──> Scheduler, VFS, Memory Manager, Device Drivers"
    note "Execute 'mode-switch' to toggle Ring privilege or 'trace ls' to inspect syscalls."
}

# cpu usage over one second, from the 'cpu' line of /proc/stat
_cpu_pct() {
    local a b idle1 tot1 idle2 tot2
    read -r -a a < <(head -1 /proc/stat)
    idle1=$(( a[4] + a[5] )); tot1=0; for v in "${a[@]:1:8}"; do tot1=$(( tot1 + v )); done
    sleep 1
    read -r -a b < <(head -1 /proc/stat)
    idle2=$(( b[4] + b[5] )); tot2=0; for v in "${b[@]:1:8}"; do tot2=$(( tot2 + v )); done
    local dt=$(( tot2 - tot1 ))
    if (( dt <= 0 )); then echo 0; else echo $(( 100 * (dt - (idle2 - idle1)) / dt )); fi
}

cmd_monitor() {
    local n=${1:-10} i cpu total avail pct
    if [[ ! $n =~ ^[1-9][0-9]*$ ]] || (( n > 60 )); then echo "  usage: monitor [refreshes 1-60]"; return 1; fi
    title "RETROOS LIVE MONITOR (${n}s in-place telemetry)"
    echo "  ${DIM}Live animated dashboard. Updating in-place every 1s...${RST}"
    echo
    trap 'echo; return 0' INT
    for (( i = 1; i <= n; i++ )); do
        cpu=$(_cpu_pct)
        total=$(_mem_kb MemTotal); avail=$(_mem_kb MemAvailable)
        pct=$(( (total - avail) * 100 / total ))
        printf "\r  ${BLD}[%02d/%02d]${RST} CPU: %s ${BLD}%3d%%${RST}  |  RAM: %s ${BLD}%3d%%${RST}  |  Load: ${CYN}%s${RST}   " \
            "$i" "$n" "$(_bar "$cpu")" "$cpu" "$(_bar "$pct")" "$pct" "$(cut -d' ' -f1 /proc/loadavg)"
    done
    echo; echo
}

cmd_modeswitch() {
    if (( KERNEL_MODE )); then
        KERNEL_MODE=0; ARROW=">"
        echo "${GRN}${BLD}[*] DROPPING PRIVILEGES: back to RING 3 (user mode, simulated)${RST}"
        note "User programs cannot touch hardware directly."
    else
        KERNEL_MODE=1; ARROW="#"
        echo "${RED}${BLD}[!] TRAP: escalated to RING 0 (kernel mode, simulated)${RST}"
        note "Kernel code may use every CPU instruction. A bug here crashes the whole OS."
        note "A real switch happens on every system call and interrupt. Prompt shows '#'."
    fi
}

cmd_trace() {
    if (( $# == 0 )); then echo "  usage: trace <command>     example: trace ls"; return 1; fi
    if ! command -v strace > /dev/null; then
        echo "  strace is not installed.  Install it:  sudo apt install strace"; return 1
    fi
    title "SYSTEM CALLS made by: $*"
    note "Each line below is one request from the program to the kernel."
    strace -f -e trace=execve,openat,read,write,fork,clone,clone3,exit_group "$@" 2>&1 | head -40
    note "(only the first 40 lines are shown)"
}
