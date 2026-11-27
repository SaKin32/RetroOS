#!/usr/bin/env bash
# modules/pcb.sh : "pcb" command - Process Control Block
#
#   pcb                      the REAL PCB the Linux kernel keeps for this shell
#   pcb <pid>                the same for any running process
#   pcb sim [q] 0:5 1:3 2:4  simulate Round Robin and show every process's state
#                            at every clock tick (New/Ready/Running/Terminated)

# ---------- real PCB (read from /proc) ----------
_pcb_real() {
    local pid=$1 f=/proc/$1
    if [[ ! -r $f/status ]]; then echo "  no such process: $pid"; return 1; fi
    local name state ppid uid thr vsz rss vol nonvol prio nice nfd
    name=$(awk '/^Name:/{print $2}' "$f/status")
    state=$(awk '/^State:/{print $2" "$3}' "$f/status")
    ppid=$(awk '/^PPid:/{print $2}' "$f/status")
    uid=$(awk '/^Uid:/{print $2}' "$f/status")
    thr=$(awk '/^Threads:/{print $2}' "$f/status")
    vsz=$(awk '/^VmSize:/{print $2" "$3}' "$f/status")
    rss=$(awk '/^VmRSS:/{print $2" "$3}' "$f/status")
    vol=$(awk '/^voluntary_ctxt_switches:/{print $2}' "$f/status")
    nonvol=$(awk '/^nonvoluntary_ctxt_switches:/{print $2}' "$f/status")
    # in /proc/PID/stat the name is in (...) and may hold spaces, so cut it off first
    read -r prio nice < <(sed 's/^.*) //' "$f/stat" | awk '{print $16, $17}')
    nfd=$(ls "$f/fd" 2> /dev/null | wc -l)
    title "PCB of process $pid  (read from /proc/$pid)"
    printf "  ${YEL}%-26s${RST} %s\n" \
        "Process ID (PID)"        "$pid" \
        "Parent PID (PPID)"       "$ppid" \
        "Program name"            "$name" \
        "Process state"           "$state" \
        "Owner (UID)"             "$uid" \
        "Priority / nice"         "$prio / $nice" \
        "Threads"                 "$thr" \
        "Virtual memory"          "${vsz:--}" \
        "Resident memory (RAM)"   "${rss:--}" \
        "Open files (fd table)"   "$nfd" \
        "Context switches (vol)"  "$vol" \
        "Context switches (forced)" "$nonvol"
    echo
    note "This is what the kernel stores in its process descriptor (task_struct):"
    note "PID, state, parent, owner, scheduling info, memory info, open files."
}

# ---------- simulated PCB / state table ----------
# pcb sim [q] at:bt ...
_pcb_sim() {
    local q=2
    if [[ $1 =~ ^[0-9]+$ ]]; then q=$1; shift; fi
    if (( q < 1 )); then echo "  quantum must be at least 1"; return 1; fi
    if (( $# == 0 )); then set -- 0:5 1:3 2:4; note "(no processes given: using 0:5 1:3 2:4)"; fi

    local -a at=() bt=() rem=() st=() wait=() ct=() queued=() queue=()
    local n=0 a i t=0 cur=-1 slice=0 done=0 line
    for a in "$@"; do
        if [[ ! $a =~ ^([0-9]+):([0-9]+)$ ]] || (( BASH_REMATCH[2] == 0 )); then
            echo "  bad process '$a'. Write arrival:burst, for example 0:5"; return 1
        fi
        at[n]=${BASH_REMATCH[1]}; bt[n]=${BASH_REMATCH[2]}; rem[n]=${bt[n]}
        st[n]=New; wait[n]=0; queued[n]=0; n=$(( n + 1 ))
    done
    if (( n > 8 )); then echo "  at most 8 processes"; return 1; fi

    title "PCB SIMULATION  (Round Robin, quantum $q)"
    echo "  State diagram:"
    echo "     ${CYN}New${RST} --admit--> ${YEL}Ready${RST} --dispatch--> ${GRN}Running${RST} --finish--> ${DIM}Terminated${RST}"
    echo "                    ^                   |"
    echo "                    +---- time slice ---+   (preempted, back to the ready queue)"
    echo
    printf "  %-5s" "time"
    for (( i = 0; i < n; i++ )); do printf " %-13s" "P$(( i + 1 ))"; done
    echo "  CPU"
    echo "  ------------------------------------------------------------------"

    while (( done < n )); do
        for (( i = 0; i < n; i++ )); do           # admit processes that have arrived
            if (( ! queued[i] && at[i] <= t )); then queue+=("$i"); queued[i]=1; st[i]=Ready; fi
        done
        if (( cur < 0 && ${#queue[@]} > 0 )); then   # dispatch the first ready process
            cur=${queue[0]}; queue=("${queue[@]:1}"); slice=0; st[cur]=Running
        fi
        line=$(printf "  %-5s" "t=$t")                # one snapshot row for this tick
        for (( i = 0; i < n; i++ )); do
            case ${st[i]} in
                New)        line+=$(printf " ${CYN}%-13s${RST}" "New") ;;
                Ready)      line+=$(printf " ${YEL}%-13s${RST}" "Ready(${rem[i]})") ;;
                Running)    line+=$(printf " ${GRN}%-13s${RST}" "RUNNING(${rem[i]})") ;;
                Terminated) line+=$(printf " ${DIM}%-13s${RST}" "Done") ;;
            esac
        done
        if (( cur >= 0 )); then line+="  ${GRN}P$(( cur + 1 ))${RST}"; else line+="  ${DIM}idle${RST}"; fi
        echo "$line"
        sleep 0.1

        for (( i = 0; i < n; i++ )); do           # every Ready process waits one more tick
            if [[ ${st[i]} == Ready ]]; then wait[i]=$(( wait[i] + 1 )); fi
        done
        if (( cur >= 0 )); then rem[cur]=$(( rem[cur] - 1 )); slice=$(( slice + 1 )); fi
        t=$(( t + 1 ))
        for (( i = 0; i < n; i++ )); do           # arrivals during this tick join the queue first
            if (( ! queued[i] && at[i] <= t )); then queue+=("$i"); queued[i]=1; st[i]=Ready; fi
        done
        if (( cur >= 0 )); then
            if (( rem[cur] == 0 )); then
                st[cur]=Terminated; ct[cur]=$t; done=$(( done + 1 )); cur=-1
            elif (( slice == q )); then
                st[cur]=Ready; queue+=("$cur"); cur=-1
            fi
        fi
    done

    echo
    echo "  ${PUR}${BLD}Final PCB table${RST}"
    printf "  %-6s %-12s %8s %7s %10s %11s %9s\n" "PID" "State" "Arrival" "Burst" "Remaining" "Completion" "Waiting"
    echo "  -------------------------------------------------------------------"
    for (( i = 0; i < n; i++ )); do
        printf "  %-6s %-12s %8s %7s %10s %11s %9s\n" "P$(( i + 1 ))" "${st[i]}" "${at[i]}" "${bt[i]}" "${rem[i]}" "${ct[i]}" "${wait[i]}"
    done
    echo
    note "Waiting = number of ticks a process spent in the Ready state."
    note "A real OS keeps one PCB like this row for every process."
}

cmd_pcb() {
    case ${1:-self} in
        self)   _pcb_real $$ ;;
        sim)    shift; _pcb_sim "$@" ;;
        *[!0-9]*) echo "  usage: pcb | pcb <pid> | pcb sim [quantum] 0:5 1:3 2:4"; return 1 ;;
        *)      _pcb_real "$1" ;;
    esac
}
