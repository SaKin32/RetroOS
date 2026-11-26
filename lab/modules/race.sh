#!/usr/bin/env bash
# modules/race.sh : MENU 1 - Race condition
#
# Several background processes add 1 to the SAME file many times.
# Adding 1 means: read the file, add 1, write the file (3 steps).
# Without a lock two processes can read the same old value, so one
# increment is lost.  A lock (lock_try / lock_release from lib/ui.sh)
# makes the 3 steps one critical section.

demo_race() {
    title "RACE CONDITION"
    note "W background processes each add 1 to one shared file N times."

    ask_int "Number of workers" 2 6;         local W=$REPLY
    ask_int "Increments per worker" 10 200;  local N=$REPLY
    local expected=$(( W * N ))
    local dir; dir=$(mktemp -d)
    local w i t0 t1

    # ---------- A) NO LOCK  (the bug) ----------
    echo 0 > "$dir/counter"
    t0=$(now_ms)
    for (( w = 0; w < W; w++ )); do
        (
            for (( i = 0; i < N; i++ )); do
                read -r v < "$dir/counter"                # step 1: read
                echo $(( v + 1 )) > "$dir/tmp.$BASHPID"   # step 2: add 1
                mv "$dir/tmp.$BASHPID" "$dir/counter"     # step 3: write (atomic rename)
            done
        ) &                                               # & = run in background
    done
    wait                                                  # wait for all workers
    t1=$(now_ms)
    local got_nolock; read -r got_nolock < "$dir/counter"
    local ms_nolock=$(( t1 - t0 ))

    # ---------- B) WITH A LOCK  (the fix) ----------
    echo 0 > "$dir/counter"
    t0=$(now_ms)
    for (( w = 0; w < W; w++ )); do
        (
            for (( i = 0; i < N; i++ )); do
                lock_wait "$dir/lock" "W$w" 100000 0.01   # ---- enter critical section
                read -r v < "$dir/counter"
                echo $(( v + 1 )) > "$dir/tmp.$BASHPID"
                mv "$dir/tmp.$BASHPID" "$dir/counter"
                lock_release "$dir/lock"                  # ---- leave critical section
            done
        ) &
    done
    wait
    t1=$(now_ms)
    local got_lock; read -r got_lock < "$dir/counter"
    local ms_lock=$(( t1 - t0 ))

    # ---------- result table ----------
    echo
    printf "  %-20s %10s %10s %10s %10s\n" "Version" "Result" "Expected" "Lost" "Time(ms)"
    echo "  ------------------------------------------------------------------"
    _race_row "No lock (BUG)"  "$got_nolock" "$expected" "$ms_nolock"
    _race_row "With lock (FIX)" "$got_lock"  "$expected" "$ms_lock"
    echo
    note "(The write uses mv, an atomic rename, so only the real race is shown.)"
    note "Why: 'add 1' = read -> add -> write. Two processes can read the same"
    note "old value, both write old+1, and one increment disappears."
    note "The lock lets only ONE process inside the read-add-write at a time"
    note "(mutual exclusion), so nothing is lost - but it is slower."
    note "Run it again: the buggy result is different every time."

    rm -rf "$dir"                                 # clean up temp files
}

# _race_row name result expected time
_race_row() {
    local name=$1 got=$2 exp=$3 ms=$4
    printf "  %-20s %10s %10s %10s %10s   " "$name" "$got" "$exp" "$(( exp - got ))" "$ms"
    if (( got == exp )); then
        echo "${GRN}CORRECT${RST}"
    else
        echo "${RED}WRONG (lost updates)${RST}"
    fi
}
