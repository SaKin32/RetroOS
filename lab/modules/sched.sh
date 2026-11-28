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

    # 1. Soft Pastel Process Badges (Modern Catppuccin / TrueColor)
    local -a bg_colors=(
        $'\033[48;2;30;45;70;38;2;137;220;235;1m'   # P1: Soft Sky Blue
        $'\033[48;2;30;55;40;38;2;166;227;161;1m'   # P2: Soft Mint Green
        $'\033[48;2;55;35;75;38;2;203;166;247;1m'   # P3: Soft Lavender
        $'\033[48;2;70;50;40;38;2;250;179;135;1m'   # P4: Soft Peach
        $'\033[48;2;60;55;35;38;2;249;226;175;1m'   # P5: Soft Yellow
        $'\033[48;2;70;40;50;38;2;243;139;168;1m'   # P6: Soft Coral
        $'\033[48;2;40;60;70;38;2;116;199;236;1m'   # P7: Sapphire
        $'\033[48;2;50;40;65;38;2;180;190;254;1m'   # P8: Periwinkle
    )
    local bg_idle=$'\033[48;2;40;40;50;38;2;147;153;178m'  # Idle: Muted Gray

    local num_segs=${#SEG_NAME[@]}
    local seg_w=6
    if (( num_segs <= 4 )); then
        seg_w=10
    elif (( num_segs <= 7 )); then
        seg_w=8
    fi

    echo
    echo "  ${CYN}${BLD}▶ Gantt Chart (Live Dispatch Simulation):${RST}"
    echo

    # Render borderless live animated Gantt stream
    echo -n "  "
    for (( k = 0; k < num_segs; k++ )); do
        name=${SEG_NAME[k]}
        local col=$bg_idle
        if [[ $name != idle ]]; then
            local p_idx=${name#P}
            col=${bg_colors[(p_idx - 1) % 8]}
        fi
        local pad_l=$(( (seg_w - 2 - ${#name}) / 2 ))
        local pad_r=$(( seg_w - 2 - ${#name} - pad_l ))
        (( pad_l < 0 )) && pad_l=0
        (( pad_r < 0 )) && pad_r=0
        printf "${col}[%*s%s%*s]${RST} " $pad_l "" "$name" $pad_r ""
        if (( ! SCH_QUIET )); then
            sleep 0.05 2> /dev/null || true
        fi
    done
    echo

    # Timeline numbers line aligned under badges
    local time_line="  ${SEG_S[0]}"
    for (( k = 0; k < num_segs; k++ )); do
        local end_val="${SEG_E[k]}"
        local spaces=$(( seg_w + 1 - ${#end_val} ))
        (( spaces < 1 )) && spaces=1
        time_line+=$(printf "%*s%s" $spaces "" "$end_val")
    done
    echo "${YEL}${BLD}${time_line}${RST}"
    echo

    # Compact Process Metrics Table (45 cols: never wraps or breaks)
    echo "  ${CYN}${BLD}Process Execution & Metrics Table:${RST}"
    echo "  ┌─────┬─────┬─────┬─────┬─────┬─────┬─────┐"
    printf "  │ ${BLD}%-3s${RST} │ ${BLD}%-3s${RST} │ ${BLD}%-3s${RST} │ ${BLD}%-3s${RST} │ ${BLD}%-3s${RST} │ ${BLD}%-3s${RST} │ ${BLD}%-3s${RST} │\n" \
        "PID" "Arr" "Brs" "Pri" "Cmp" "TAT" "WT"
    echo "  ├─────┼─────┼─────┼─────┼─────┼─────┼─────┤"
    for (( i = 0; i < SCH_N; i++ )); do
        tat=$(( CT[i] - AT[i] )); wt=$(( tat - BT[i] ))
        local pcol=${bg_colors[i % 8]}
        printf "  │ ${pcol}%-3s${RST} │ %3d │ %3d │ %3d │ %3d │ %3d │ %3d │\n" \
            "P$(( i + 1 ))" "${AT[i]}" "${BT[i]}" "${PR[i]}" "${CT[i]}" "$tat" "$wt"
    done
    echo "  └─────┴─────┴─────┴─────┴─────┴─────┴─────┘"
    echo "  ┌─────────────────────────────────────────┐"
    printf "  │  Average Turnaround :  ${GRN}${BLD}%-6s ms${RST}        │\n" "$SCH_AVG_T"
    printf "  │  Average Waiting    :  ${YEL}${BLD}%-6s ms${RST}        │\n" "$SCH_AVG_W"
    echo "  └─────────────────────────────────────────┘"
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
    echo "  ┌──────────────────────┬─────────────┬─────────────┐"
    printf "  │ ${BLD}%-20s${RST} │ ${BLD}%-11s${RST} │ ${BLD}%-11s${RST} │\n" "Algorithm" "Avg Turn" "Avg Wait"
    echo "  ├──────────────────────┼─────────────┼─────────────┤"
    for a in fcfs sjf prio rr; do
        _sch_run "$a"
        case $a in fcfs) lbl="FCFS";; sjf) lbl="SJF";; prio) lbl="Priority";; rr) lbl="Round Robin (q=2)";; esac
        printf "  │ ${WHT}%-20s${RST} │ %8s ms │ %8s ms │\n" "$lbl" "$SCH_AVG_T" "$SCH_AVG_W"
        if awk -v a="$SCH_AVG_W" -v b="$bestw" 'BEGIN{exit !(a<b)}'; then best=$lbl; bestw=$SCH_AVG_W; fi
    done
    echo "  └──────────────────────┴─────────────┴─────────────┘"
    echo
    echo "  ${GRN}${BLD}★ Best Performance (Lowest Avg Waiting): ${WHT}${best} (${bestw} ms)${RST}"
    note "SJF minimizes average waiting time; Round Robin provides fair time-sharing."
    echo
}
