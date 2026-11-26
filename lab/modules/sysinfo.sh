#!/usr/bin/env bash
# modules/sysinfo.sh : kernel and memory information
#
#   kinfo          what the kernel tells us (version, uptime, processes ...)
#   meminfo        RAM usage from /proc/meminfo
#   monitor [n]    live CPU and RAM bars, n refreshes (default 5)
#   mode-switch    toggle a SIMULATED privilege level (Ring 3 user <-> Ring 0 kernel)
#   trace <cmd>    show the system calls a program makes (needs strace)

KERNEL_MODE=0

# _bar PERCENT -> a 20 character bar like [#####---------------]
_bar() {
    local pct=$1 i out="" full=$(( $1 * 20 / 100 ))
    for (( i = 0; i < 20; i++ )); do
        if (( i < full )); then out+="#"; else out+="-"; fi
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
    title "MEMORY INFO  (from /proc/meminfo)"
    printf "  %-16s %8s MB\n" "Total RAM"  $(( total / 1024 ))
    printf "  %-16s %8s MB\n" "Used"       $(( used / 1024 ))
    printf "  %-16s %8s MB\n" "Available"  $(( avail / 1024 ))
    printf "  %-16s %8s MB\n" "Free (unused)" $(( free / 1024 ))
    printf "  %-16s %8s MB used of %s MB\n" "Swap" $(( (swt - swf) / 1024 )) $(( swt / 1024 ))
    echo
    echo "  RAM  ${GRN}$(_bar $pct)${RST} ${pct}%"
    note "Available > Free because the kernel also uses spare RAM as a disk cache"
    note "and gives it back to programs when they need it."
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
    title "KERNEL INFO"
    printf "  ${YEL}%-22s${RST} %s\n" \
        "Kernel name"        "$(uname -s)" \
        "Kernel release"     "$(uname -r)" \
        "Architecture"       "$(uname -m)" \
        "Uptime"             "${days}d ${hrs}h ${mins}m" \
        "Boot time"          "$(date -d @"$btime" '+%Y-%m-%d %H:%M' 2> /dev/null)" \
        "CPU cores"          "$cpus" \
        "Load average"       "$load" \
        "Running processes"  "$procs" \
        "Context switches"   "$ctxt (since boot)" \
        "Our privilege mode" "$( (( KERNEL_MODE )) && echo 'Ring 0 (simulated)' || echo 'Ring 3 - user mode')"
    echo
    echo "  How a command reaches the kernel:"
    echo "    ${CYN}You type 'ls'${RST}"
    echo "       |  RetroOS shell (user mode)   fork() -> exec()"
    echo "       v"
    echo "    ${PUR}System call interface${RST}   (trap: switch to kernel mode)"
    echo "       v"
    echo "    ${RED}Linux kernel${RST}  scheduler | memory manager | file system | drivers"
    echo "       v"
    echo "    Hardware  (CPU, RAM, disk)"
    note "Try:  trace ls     to watch the real system calls."
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
    local n=${1:-5} i cpu total avail pct
    if [[ ! $n =~ ^[1-9][0-9]*$ ]] || (( n > 60 )); then echo "  usage: monitor [refreshes 1-60]"; return 1; fi
    title "RETROOS MONITOR  (${n} refreshes, 1 second each)"
    for (( i = 1; i <= n; i++ )); do
        cpu=$(_cpu_pct)
        total=$(_mem_kb MemTotal); avail=$(_mem_kb MemAvailable)
        pct=$(( (total - avail) * 100 / total ))
        printf "  CPU ${CYN}%s${RST} %3d%%   RAM ${GRN}%s${RST} %3d%%   load %s\n" \
            "$(_bar "$cpu")" "$cpu" "$(_bar "$pct")" "$pct" "$(cut -d' ' -f1 /proc/loadavg)"
    done
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
