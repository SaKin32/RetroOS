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

# _sch_report -> Colorful Graphical Gantt Chart + styled table + averages
_sch_report() {
    local i k sumt=0 sumw=0 tat wt
    for (( i = 0; i < SCH_N; i++ )); do           # averages (also used by 'sched compare')
        tat=$(( CT[i] - AT[i] )); wt=$(( tat - BT[i] ))
        sumt=$(( sumt + tat )); sumw=$(( sumw + wt ))
    done
    SCH_AVG_T=$(awk -v s=$sumt -v n=$SCH_N 'BEGIN{printf "%.2f", s/n}')
    SCH_AVG_W=$(awk -v s=$sumw -v n=$SCH_N 'BEGIN{printf "%.2f", s/n}')
    (( SCH_QUIET )) && return 0

    # 1. Vibrant Process Background Colors (ANSI 256/TrueColor)
    local -a bg_colors=(
        $'\033[44;1;97m'   # P1: Blue
        $'\033[42;1;30m'   # P2: Green
        $'\033[45;1;97m'   # P3: Magenta
        $'\033[43;1;30m'   # P4: Yellow/Amber
        $'\033[46;1;30m'   # P5: Cyan
        $'\033[41;1;97m'   # P6: Red
        $'\033[105;1;97m'  # P7: Bright Magenta
        $'\033[104;1;97m'  # P8: Bright Blue
    )
    local bg_idle=$'\033[100;1;97m'  # Idle: Dark Gray

    local num_segs=${#SEG_NAME[@]}
    local -a widths=()
    local seg_w d name s e

    # Calculate optimal segment widths
    for (( k = 0; k < num_segs; k++ )); do
        s=${SEG_S[k]}; e=${SEG_E[k]}; d=$(( e - s ))
        if (( num_segs <= 6 )); then
            seg_w=$(( d * 2 ))
            (( seg_w < 6 )) && seg_w=6
            (( seg_w > 16 )) && seg_w=16
        else
            seg_w=$(( d + 3 ))
            (( seg_w < 5 )) && seg_w=5
            (( seg_w > 10 )) && seg_w=10
        fi
        widths[k]=$seg_w
    done

    echo
    echo "  ${CYN}${BLD}Gantt Chart Timeline (Visualized):${RST}"
    echo

    # Top border
    echo -n "  ┌"
    for (( k = 0; k < num_segs; k++ )); do
        local w=${widths[k]}
        printf '─%.0s' $(seq 1 $w)
        if (( k < num_segs - 1 )); then echo -n "┬"; else echo "┐"; fi
    done

    # Middle bar with colored background blocks
    echo -n "  │"
    for (( k = 0; k < num_segs; k++ )); do
        local w=${widths[k]}
        name=${SEG_NAME[k]}
        local col=$bg_idle
        if [[ $name != idle ]]; then
            local p_idx=${name#P}
            col=${bg_colors[(p_idx - 1) % 8]}
        fi
        local pad_l=$(( (w - ${#name}) / 2 ))
        local pad_r=$(( w - ${#name} - pad_l ))
        printf "${col}%*s%s%*s${RST}│" $pad_l "" "$name" $pad_r ""
    done
    echo

    # Bottom border
    echo -n "  └"
    for (( k = 0; k < num_segs; k++ )); do
        local w=${widths[k]}
        printf '─%.0s' $(seq 1 $w)
        if (( k < num_segs - 1 )); then echo -n "┴"; else echo "┘"; fi
    done

    # Timeline numbers line
    local time_line="  ${SEG_S[0]}"
    for (( k = 0; k < num_segs; k++ )); do
        local end_val="${SEG_E[k]}"
        local w=${widths[k]}
        local spaces=$(( w + 1 - ${#end_val} ))
        (( spaces < 1 )) && spaces=1
        time_line+=$(printf "%*s%s" $spaces "" "$end_val")
    done
    echo "${YEL}${BLD}${time_line}${RST}"
    echo

    # Process Metrics Table
    echo "  ${CYN}${BLD}Process Execution & Metrics Table:${RST}"
    echo "  ┌─────────┬─────────┬───────┬──────────┬────────────┬────────────┬─────────┐"
    printf "  │ ${BLD}%-7s${RST} │ ${BLD}%-7s${RST} │ ${BLD}%-5s${RST} │ ${BLD}%-8s${RST} │ ${BLD}%-10s${RST} │ ${BLD}%-10s${RST} │ ${BLD}%-7s${RST} │\n" \
        "Process" "Arrival" "Burst" "Priority" "Completion" "Turnaround" "Waiting"
    echo "  ├─────────┼─────────┼───────┼──────────┼────────────┼────────────┼─────────┤"
    sumt=0; sumw=0
    for (( i = 0; i < SCH_N; i++ )); do
        tat=$(( CT[i] - AT[i] )); wt=$(( tat - BT[i] ))
        sumt=$(( sumt + tat )); sumw=$(( sumw + wt ))
        local pcol=${bg_colors[i % 8]}
        printf "  │ ${pcol} %-5s ${RST} │ %7s │ %5s │ %8s │ %10s │ %10s │ %7s │\n" \
            "P$(( i + 1 ))" "${AT[i]}" "${BT[i]}" "${PR[i]}" "${CT[i]}" "$tat" "$wt"
    done
    echo "  └─────────┴─────────┴───────┴──────────┴────────────┴────────────┴─────────┘"
    echo
    echo "  ┌────────────────────────────────────────────────────────┐"
    printf "  │  Average Turnaround Time :  ${GRN}${BLD}%-6s ms${RST}                       │\n" "$SCH_AVG_T"
    printf "  │  Average Waiting Time    :  ${YEL}${BLD}%-6s ms${RST}                       │\n" "$SCH_AVG_W"
    echo "  └────────────────────────────────────────────────────────┘"
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

# sched compare : same processes, every algorithm, beautiful comparison box table
_sch_compare() {
    local a best="" bestw=999999 lbl
    echo
    echo "  ${CYN}${BLD}CPU Scheduling Benchmark & Performance Comparison:${RST}"
    echo "  ┌────────────────────────┬──────────────────┬──────────────────┐"
    printf "  │ ${BLD}%-22s${RST} │ ${BLD}%-16s${RST} │ ${BLD}%-16s${RST} │\n" "Algorithm" "Avg Turnaround" "Avg Waiting Time"
    echo "  ├────────────────────────┼──────────────────┼──────────────────┤"
    for a in fcfs sjf prio rr; do
        _sch_run "$a"
        case $a in fcfs) lbl="FCFS";; sjf) lbl="SJF";; prio) lbl="Priority";; rr) lbl="Round Robin (q=2)";; esac
        printf "  │ ${WHT}%-22s${RST} │ %13s ms │ %13s ms │\n" "$lbl" "$SCH_AVG_T" "$SCH_AVG_W"
        if awk -v a="$SCH_AVG_W" -v b="$bestw" 'BEGIN{exit !(a<b)}'; then best=$lbl; bestw=$SCH_AVG_W; fi
    done
    echo "  └────────────────────────┴──────────────────┴──────────────────┘"
    echo
    echo "  ${GRN}${BLD}★ Best Performance (Lowest Avg Waiting): ${WHT}${best} (${bestw} ms)${RST}"
    note "SJF minimizes average waiting time; Round Robin provides fair time-sharing."
    echo
}
