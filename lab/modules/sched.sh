#!/usr/bin/env bash
# modules/sched.sh : "sched" command - CPU scheduling with a Gantt chart
#
#   sched fcfs 0:5 1:3 2:8        first come first served
#   sched sjf  0:5 1:3 2:8        shortest job first (non-preemptive)
#   sched rr 2 0:5 1:3 2:8        round robin, time quantum 2
#   sched prio 0:5:2 1:3:1 2:8:3  priority (non-preemptive), 3rd number = priority
#                                 (SMALLER number = MORE important)
#   sched compare 0:5 1:3 2:8     run all algorithms and compare the averages
# Each process is  arrival:burst   (or arrival:burst:priority)

# _sch_load arrival:burst ...  -> fills AT[] (arrival) and BT[] (burst)
_sch_load() {
    local a
    AT=(); BT=(); PR=(); SCH_N=0
    for a in "$@"; do
        if [[ ! $a =~ ^([0-9]+):([0-9]+)(:([0-9]+))?$ ]]; then
            echo "  bad process '$a'. Write arrival:burst, for example 0:5"; return 1
        fi
        if (( BASH_REMATCH[2] == 0 )); then echo "  burst time must be at least 1"; return 1; fi
        AT[SCH_N]=${BASH_REMATCH[1]}; BT[SCH_N]=${BASH_REMATCH[2]}
        PR[SCH_N]=${BASH_REMATCH[4]:-1}               # priority (default 1)
        SCH_N=$(( SCH_N + 1 ))
    done
    if (( SCH_N == 0 )); then echo "  give at least one process, for example: sched fcfs 0:5 1:3"; return 1; fi
    if (( SCH_N > 12 )); then echo "  at most 12 processes"; return 1; fi
}

# _sch_seg NAME START END -> remember one piece of the Gantt chart
_sch_seg() { SEG_NAME+=("$1"); SEG_S+=("$2"); SEG_E+=("$3"); }

# non-preemptive: policy fcfs (earliest arrival), sjf (shortest burst)
# or prio (smallest priority number first)
_sch_nonpre() {
    local policy=$1 t=0 done=0 i best nxt
    local -a fin=()
    while (( done < SCH_N )); do
        best=-1
        for (( i = 0; i < SCH_N; i++ )); do
            (( fin[i] )) && continue              # already finished
            (( AT[i] > t )) && continue           # has not arrived yet
            if (( best < 0 )); then
                best=$i
            elif [[ $policy == sjf ]]; then
                (( BT[i] < BT[best] )) && best=$i
            elif [[ $policy == prio ]]; then
                (( PR[i] < PR[best] )) && best=$i
            else
                (( AT[i] < AT[best] )) && best=$i
            fi
        done
        if (( best < 0 )); then                   # nobody is ready: CPU idle until next arrival
            nxt=-1
            for (( i = 0; i < SCH_N; i++ )); do
                (( fin[i] )) && continue
                if (( nxt < 0 || AT[i] < nxt )); then nxt=${AT[i]}; fi
            done
            _sch_seg idle "$t" "$nxt"; t=$nxt; continue
        fi
        _sch_seg "P$(( best + 1 ))" "$t" "$(( t + BT[best] ))"
        t=$(( t + BT[best] )); CT[best]=$t; fin[best]=1; done=$(( done + 1 ))
    done
}

# round robin with time quantum $1
_sch_rr() {
    local q=$1 t=0 done=0 i cur run nxt
    local -a rem=("${BT[@]}") queued=() queue=()
    while (( done < SCH_N )); do
        for (( i = 0; i < SCH_N; i++ )); do       # put arrived processes in the queue
            if (( ! queued[i] && AT[i] <= t )); then queue+=("$i"); queued[i]=1; fi
        done
        if (( ${#queue[@]} == 0 )); then          # idle: jump to next arrival
            nxt=-1
            for (( i = 0; i < SCH_N; i++ )); do
                (( queued[i] )) && continue
                if (( nxt < 0 || AT[i] < nxt )); then nxt=${AT[i]}; fi
            done
            _sch_seg idle "$t" "$nxt"; t=$nxt; continue
        fi
        cur=${queue[0]}; queue=("${queue[@]:1}")  # take the first process in the queue
        run=$(( rem[cur] < q ? rem[cur] : q ))
        _sch_seg "P$(( cur + 1 ))" "$t" "$(( t + run ))"
        t=$(( t + run )); rem[cur]=$(( rem[cur] - run ))
        for (( i = 0; i < SCH_N; i++ )); do       # new arrivals go BEFORE the preempted process
            if (( ! queued[i] && AT[i] <= t )); then queue+=("$i"); queued[i]=1; fi
        done
        if (( rem[cur] > 0 )); then queue+=("$cur"); else CT[cur]=$t; done=$(( done + 1 )); fi
    done
}

# _sch_report -> Gantt chart + table + averages
_sch_report() {
    local i k sumt=0 sumw=0 tat wt
    local -a pal=("$CYN" "$GRN" "$YEL" "$RED")
    for (( i = 0; i < SCH_N; i++ )); do           # averages (also used by 'sched compare')
        tat=$(( CT[i] - AT[i] )); wt=$(( tat - BT[i] ))
        sumt=$(( sumt + tat )); sumw=$(( sumw + wt ))
    done
    SCH_AVG_T=$(awk -v s=$sumt -v n=$SCH_N 'BEGIN{printf "%.2f", s/n}')
    SCH_AVG_W=$(awk -v s=$sumw -v n=$SCH_N 'BEGIN{printf "%.2f", s/n}')
    (( SCH_QUIET )) && return 0
    sumt=0; sumw=0
    echo
    echo -n "  "
    for (( k = 0; k < ${#SEG_NAME[@]}; k++ )); do
        if [[ ${SEG_NAME[k]} == idle ]]; then
            echo -n "${DIM}[idle ${SEG_S[k]}-${SEG_E[k]}]${RST} "
        else
            i=${SEG_NAME[k]#P}
            echo -n "${pal[(i - 1) % 4]}[${SEG_NAME[k]} ${SEG_S[k]}-${SEG_E[k]}]${RST} "
        fi
    done
    echo; echo
    printf "  %-8s %8s %8s %8s %12s %12s %10s\n" "Process" "Arrival" "Burst" "Priority" "Completion" "Turnaround" "Waiting"
    echo "  ----------------------------------------------------------------------------"
    for (( i = 0; i < SCH_N; i++ )); do
        tat=$(( CT[i] - AT[i] )); wt=$(( tat - BT[i] ))
        sumt=$(( sumt + tat )); sumw=$(( sumw + wt ))
        printf "  %-8s %8s %8s %8s %12s %12s %10s\n" "P$(( i + 1 ))" "${AT[i]}" "${BT[i]}" "${PR[i]}" "${CT[i]}" "$tat" "$wt"
    done
    echo
    echo "  Average turnaround time: ${BLD}${SCH_AVG_T}${RST}"
    echo "  Average waiting time:    ${BLD}${SCH_AVG_W}${RST}"
    echo
}

cmd_sched() {
    local algo=$1 q
    AT=(); BT=(); PR=(); CT=(); SEG_NAME=(); SEG_S=(); SEG_E=(); SCH_QUIET=0
    case $algo in
        compare)
            shift; _sch_load "$@" || return 1
            _sch_compare; return ;;
        fcfs|sjf|prio)
            shift; _sch_load "$@" || return 1
            _sch_nonpre "$algo" ;;
        rr)
            q=$2
            if [[ ! $q =~ ^[1-9][0-9]*$ ]]; then
                echo "  usage: sched rr <quantum> <arrival:burst> ...   example: sched rr 2 0:5 1:3 2:8"; return 1
            fi
            shift 2; _sch_load "$@" || return 1
            _sch_rr "$q" ;;
        *)
            echo "  usage:"
            echo "    sched fcfs 0:5 1:3 2:8        (arrival:burst for every process)"
            echo "    sched sjf  0:5 1:3 2:8"
            echo "    sched rr 2 0:5 1:3 2:8        (2 = time quantum)"
            echo "    sched prio 0:5:2 1:3:1 2:8:3  (arrival:burst:priority, small number = important)"
            echo "    sched compare 0:5 1:3 2:8     (all algorithms side by side)"
            return 1 ;;
    esac
    _sch_report
}

# _sch_run NAME  -> run one algorithm quietly on the already loaded processes
_sch_run() {
    CT=(); SEG_NAME=(); SEG_S=(); SEG_E=(); SCH_QUIET=1
    case $1 in
        rr) _sch_rr 2 ;;
        *)  _sch_nonpre "$1" ;;
    esac
    _sch_report
    SCH_QUIET=0
}

# sched compare : same processes, every algorithm, one table
_sch_compare() {
    local a best="" bestw=999999 lbl
    echo
    printf "  %-22s %16s %16s\n" "Algorithm" "Avg turnaround" "Avg waiting"
    echo "  ----------------------------------------------------------"
    for a in fcfs sjf prio rr; do
        _sch_run "$a"
        case $a in fcfs) lbl="FCFS";; sjf) lbl="SJF";; prio) lbl="Priority";; rr) lbl="Round Robin (q=2)";; esac
        printf "  %-22s %16s %16s\n" "$lbl" "$SCH_AVG_T" "$SCH_AVG_W"
        if awk -v a="$SCH_AVG_W" -v b="$bestw" 'BEGIN{exit !(a<b)}'; then best=$lbl; bestw=$SCH_AVG_W; fi
    done
    echo
    echo "  Lowest average waiting time: ${GRN}${BLD}${best}${RST} (${bestw})"
    note "SJF always gives the smallest average waiting time, but long jobs can wait"
    note "very long (starvation). Priority has the same risk for low-priority jobs."
    echo
}
