#!/usr/bin/env bash
# modules/deadlock.sh : MENU 2 - Deadlock
#
# Two locks (lock files A and B) use lock_try / lock_wait from lib/ui.sh.
#   T1 takes A then B       T2 takes B then A   ->  DEADLOCK
# Each worker waits at most 3 seconds so the demo finishes; a real
# deadlock would wait forever.

# _dl_log who message   -> prints a time-stamped line
_dl_log() {
    printf "  %s[%5d ms]%s %s: %s\n" "$DIM" $(( $(now_ms) - DL_T0 )) "$RST" "$1" "$2"
}

# _dl_worker NAME FIRST SECOND DIR MODE
#   MODE = block   : wait for the second lock (can deadlock)
#   MODE = backoff : if the second lock is busy, give up the first and retry
_dl_worker() {
    local who=$1 first=$2 second=$3 dir=$4 mode=$5
    local L1="$dir/lock$first" L2="$dir/lock$second"

    if [[ $mode == backoff ]]; then
        local tries
        for (( tries = 1; tries <= 10; tries++ )); do
            lock_wait "$L1" "$who" 200 0.05
            _dl_log "$who" "locked $first"
            sleep 1
            if lock_try "$L2" "$who"; then       # try once, never wait
                _dl_log "$who" "${GRN}got $second too -> working${RST}"
                sleep 0.5
                lock_release "$L2"; lock_release "$L1"
                _dl_log "$who" "released both"
                return
            fi
            _dl_log "$who" "${YEL}$second is busy -> release $first and retry${RST}"
            lock_release "$L1"
            sleep "0.$(( RANDOM % 6 + 2 ))"      # random back-off
        done
        return
    fi

    lock_wait "$L1" "$who" 200 0.05
    _dl_log "$who" "locked $first"
    sleep 1                                      # let the other worker take its lock
    _dl_log "$who" "now waiting for $second ..."
    if lock_wait "$L2" "$who" 30 0.1; then       # 30 x 0.1 s = wait at most 3 seconds
        _dl_log "$who" "${GRN}got $second too -> working${RST}"
        sleep 0.5
        lock_release "$L2"
        _dl_log "$who" "released $second"
    else
        _dl_log "$who" "${RED}TIMEOUT waiting for $second  => DEADLOCK${RST}"
        : > "$dir/gaveup_$who"
        # keep holding $first until the other worker also gave up
        for _ in {1..50}; do
            [[ -e $dir/gaveup_T1 && -e $dir/gaveup_T2 ]] && break
            sleep 0.1
        done
    fi
    lock_release "$L1"
    _dl_log "$who" "released $first"
}

# _dl_run MODE   MODE = deadlock | order | backoff
_dl_run() {
    local mode=$1 dir p1 p2
    dir=$(mktemp -d)
    DL_T0=$(now_ms)

    case $mode in
        deadlock) ( _dl_worker T1 A B "$dir" block ) &   p1=$!
                  ( _dl_worker T2 B A "$dir" block ) &   p2=$! ;;
        order)    ( _dl_worker T1 A B "$dir" block ) &   p1=$!
                  ( _dl_worker T2 A B "$dir" block ) &   p2=$! ;;
        backoff)  ( _dl_worker T1 A B "$dir" backoff ) & p1=$!
                  ( _dl_worker T2 B A "$dir" backoff ) & p2=$! ;;
    esac

    if [[ $mode == deadlock ]]; then
        sleep 2
        echo
        echo "  ${CYN}Look from outside while they are stuck${RST}"
        echo "    lock A is held by: $(lock_holder "$dir/lockA")"
        echo "    lock B is held by: $(lock_holder "$dir/lockB")"
        echo "    worker processes (ps):"
        if ps -o pid,ppid,stat,args -p "$p1,$p2" > /dev/null 2>&1; then
            ps -o pid,ppid,stat,args -p "$p1,$p2" | sed 's/^/      /'          # Linux
        else
            ps | grep -E "(^|[^0-9])($p1|$p2)([^0-9]|\$)" | sed 's/^/      /'  # Git Bash
        fi
        note "Both workers are alive but make no progress: each keeps trying for a lock"
        note "that the other one holds, and neither will give its own lock up."
        echo
    fi
    wait "$p1" "$p2"
    rm -rf "$dir"
}

demo_deadlock() {
    title "DEADLOCK SIMULATION & PREVENTION (CSE210)"
    local choice
    while true; do
        echo
        echo "  ${PUR}┌──${CYN} Deadlock Scenarios & Mitigation ${PUR}───────────┐${RST}"
        echo "  ${PUR}│${RST}  ${GRN}1)${RST} ${BLD}Simulate Deadlock${RST}   (Circular Wait)      ${PUR}│${RST}"
        echo "  ${PUR}│${RST}  ${GRN}2)${RST} ${BLD}Fix: Lock Ordering${RST}  (Global order A->B)  ${PUR}│${RST}"
        echo "  ${PUR}│${RST}  ${GRN}3)${RST} ${BLD}Fix: Back-off/Retry${RST} (Trylock & Backoff)  ${PUR}│${RST}"
        echo "  ${PUR}│${RST}  ${GRN}4)${RST} ${BLD}Coffman Conditions${RST}  (4 Necessary Rules)  ${PUR}│${RST}"
        echo "  ${PUR}│${RST}  ${RED}0)${RST} Return to Shell                          ${PUR}│${RST}"
        echo "  ${PUR}└──────────────────────────────────────────────┘${RST}"
        ask_int "Select Option" 0 4; choice=$REPLY

        case $choice in
            1)  echo
                note "T1 holds A and requests B; T2 holds B and requests A."
                note "(3-second timeout safety limit applied to end simulation cleanly)"
                echo
                _dl_run deadlock
                echo
                echo "  ${RED}${BLD}Wait-for Graph Cycle Detected:${RST}"
                echo "  ${RED}  [T1] ──wants──> (Lock B) ──held by──> [T2] ──wants──> (Lock A) ──held by──> [T1]${RST}"
                note "A directed cycle in the resource allocation graph confirms Deadlock." ;;
            2)  echo
                note "Both workers acquire locks in identical global hierarchy (A -> B)."
                echo
                _dl_run order
                echo "  ${GRN}${BLD}✔ Deadlock Prevented: Circular Wait condition eliminated.${RST}" ;;
            3)  echo
                note "Non-blocking trylock: if secondary lock is busy, release primary lock and back-off."
                echo
                _dl_run backoff
                echo "  ${GRN}${BLD}✔ Deadlock Prevented: Hold & Wait condition broken.${RST}" ;;
            4)  echo
                echo "  ${CYN}${BLD}Coffman's Four Necessary Conditions for Deadlock:${RST}"
                echo "   ${RED}[1] Mutual Exclusion${RST} : Only one process can hold a resource at a time."
                echo "   ${RED}[2] Hold and Wait   ${RST} : A process holds resources while requesting new ones."
                echo "   ${RED}[3] No Preemption   ${RST} : Resources cannot be forcibly seized from processes."
                echo "   ${RED}[4] Circular Wait   ${RST} : Circular chain of processes each waiting for the next."
                echo
                echo "  ${GRN}${BLD}Prevention Strategies (Breaking Conditions):${RST}"
                echo "   ${GRN}✔ Break #4 (Circular Wait)${RST}   : Global Lock Ordering (Option 2)"
                echo "   ${GRN}✔ Break #2 (Hold & Wait)  ${RST}   : Non-blocking Back-off / trylock (Option 3)"
                echo "   ${GRN}✔ Deadlock Avoidance      ${RST}   : Dijkstra's Banker's Algorithm (Run: bankers)" ;;
            0)  echo; return ;;
        esac
    done
}
