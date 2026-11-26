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
    title "DEADLOCK"
    local choice
    while true; do
        echo
        echo "  1) Cause a deadlock    (T1: A then B,  T2: B then A)"
        echo "  2) Fix: lock ORDERING  (both take A then B)"
        echo "  3) Fix: back-off       (if second lock busy, release first and retry)"
        echo "  4) Show the 4 Coffman conditions"
        echo "  0) Back"
        ask_int "Choose" 0 4; choice=$REPLY

        case $choice in
            1)  echo
                note "T1 holds A and wants B.  T2 holds B and wants A.  Neither can move."
                note "(Each waits only 3 s so the demo ends instead of hanging forever.)"
                echo
                _dl_run deadlock
                echo
                echo "  ${RED}Wait-for graph:  T1 --wants--> B --held by--> T2 --wants--> A --held by--> T1${RST}"
                note "A cycle in the wait-for graph means deadlock." ;;
            2)  echo
                note "Both workers take the locks in the SAME global order: A first, then B."
                echo
                _dl_run order
                note "Deadlock PREVENTION: breaks the 'circular wait' condition." ;;
            3)  echo
                note "lock_try never waits. If B is busy, the worker releases A and tries later."
                echo
                _dl_run backoff
                note "Breaks 'hold and wait': a worker never waits while holding a lock." ;;
            4)  echo
                echo "  Deadlock needs ALL four at once:"
                echo "   1. Mutual exclusion  - a lock is held by one process at a time"
                echo "   2. Hold and wait     - a process holds one lock while asking for another"
                echo "   3. No preemption     - a lock cannot be taken away by force"
                echo "   4. Circular wait     - T1 waits for T2 and T2 waits for T1"
                echo "  Break any one of them and deadlock is impossible."
                echo "   - Lock ordering    breaks #4"
                echo "   - Back-off/trylock breaks #2"
                echo "   - Banker's (command: bankers) avoids unsafe states before they happen" ;;
            0)  return ;;
        esac
    done
}
