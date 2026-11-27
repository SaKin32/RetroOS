#!/usr/bin/env bash
# modules/bankers.sh : MENU 4 - Banker's algorithm (deadlock AVOIDANCE)
#
# The OS grants a request only if the system stays in a SAFE state.
# Matrices are stored as flat arrays:  element (i,j) = array[ i*M + j ]

N=0; M=0
AVAIL=(); ALLOC=(); MAXM=(); NEED=()

# ---------- small helpers ----------

# _vec ARRAYNAME START : print M numbers of that array from index START as [a b c]
_vec() {
    local -n arr=$1
    local s=$2 j out=""
    for (( j = 0; j < M; j++ )); do out+="${arr[s+j]} "; done
    echo "[${out% }]"
}

_recompute_need() {
    local i j
    NEED=()
    for (( i = 0; i < N; i++ )); do
        for (( j = 0; j < M; j++ )); do
            NEED[i*M+j]=$(( MAXM[i*M+j] - ALLOC[i*M+j] ))
        done
    done
}

# _le A_NAME A_START B_NAME B_START : succeed if every a[j] <= b[j]
_le() {
    local -n a=$1; local -n b=$3
    local as=$2 bs=$4 j
    for (( j = 0; j < M; j++ )); do
        (( a[as+j] <= b[bs+j] )) || return 1
    done
    return 0
}

_print_state() {
    local i
    echo
    printf "  %-6s %-16s %-16s %-16s\n" "Proc" "Allocation" "Max" "Need"
    echo "  ----------------------------------------------------"
    for (( i = 0; i < N; i++ )); do
        printf "  %-6s %-16s %-16s %-16s\n" "P$i" "$(_vec ALLOC $((i*M)))" "$(_vec MAXM $((i*M)))" "$(_vec NEED $((i*M)))"
    done
    echo "  Available: ${BLD}$(_vec AVAIL 0)${RST}"
}

# ---------- the safety algorithm ----------
# _is_safe VERBOSE(0/1)   -> sets SEQ=( safe sequence ), succeeds if state is safe
_is_safe() {
    local verbose=$1
    local -a WORK FIN
    local i j round found
    WORK=("${AVAIL[@]}")
    SEQ=()
    for (( i = 0; i < N; i++ )); do FIN[i]=0; done

    (( verbose )) && echo && echo "  Safety check. Work starts as Available = $(_vec WORK 0)"

    for (( round = 0; round < N; round++ )); do
        found=0
        for (( i = 0; i < N; i++ )); do
            (( FIN[i] )) && continue
            if _le NEED $(( i*M )) WORK 0; then          # Need[i] <= Work ?
                if (( verbose )); then
                    echo -n "   P$i: Need $(_vec NEED $((i*M))) <= Work $(_vec WORK 0)  -> can finish, returns $(_vec ALLOC $((i*M)))"
                fi
                for (( j = 0; j < M; j++ )); do WORK[j]=$(( WORK[j] + ALLOC[i*M+j] )); done
                (( verbose )) && echo "  -> Work = $(_vec WORK 0)"
                FIN[i]=1; SEQ+=("$i"); found=1
                break
            fi
        done
        (( found )) || break
    done

    if (( verbose && ${#SEQ[@]} < N )); then
        echo -n "   Stuck. No unfinished process has Need <= Work $(_vec WORK 0). Unfinished:"
        for (( i = 0; i < N; i++ )); do (( FIN[i] )) || echo -n " P$i"; done
        echo
    fi
    (( ${#SEQ[@]} == N ))
}

# _seq_str : "<P1, P3, P0>" from SEQ
_seq_str() {
    local s="" x
    for x in "${SEQ[@]}"; do s+="P$x, "; done
    echo "<${s%, }>"
}

_report_safety() {
    if _is_safe 1; then
        echo
        echo "  ${GRN}${BLD}✔ SYSTEM IS IN A SAFE STATE!${RST} Valid Safe Sequence: ${CYN}${BLD}$(_seq_str)${RST}"
    else
        echo
        echo "  ${RED}${BLD}✘ SYSTEM IS IN AN UNSAFE STATE!${RST} No deadlock-free execution order exists."
    fi
}

# ---------- resource request ----------
_request() {
    local p j
    local -a REQ
    ask_int "Which process requests" 0 $(( N - 1 )); p=$REPLY
    for (( j = 0; j < M; j++ )); do
        ask_int "  Request for resource $(printf "\\x$(printf %x $((65 + j)))")" 0 1000
        REQ[j]=$REPLY
    done
    echo
    echo "  P$p requests $(_vec REQ 0)"

    # step 1: request <= Need ?
    if ! _le REQ 0 NEED $(( p*M )); then
        echo "  ${RED}DENIED:${RST} request exceeds P$p's declared maximum claim (Need $(_vec NEED $((p*M))))."
        return
    fi
    # step 2: request <= Available ?
    if ! _le REQ 0 AVAIL 0; then
        echo "  ${YEL}WAIT:${RST} resources not available now (Available $(_vec AVAIL 0)). P$p must wait."
        return
    fi

    # step 3: pretend to allocate, then test safety
    local -a S_AVAIL=("${AVAIL[@]}") S_ALLOC=("${ALLOC[@]}") S_NEED=("${NEED[@]}")
    for (( j = 0; j < M; j++ )); do
        AVAIL[j]=$(( AVAIL[j] - REQ[j] ))
        ALLOC[p*M+j]=$(( ALLOC[p*M+j] + REQ[j] ))
        NEED[p*M+j]=$(( NEED[p*M+j] - REQ[j] ))
    done
    echo "  Pretend to grant it, then check safety..."
    if _is_safe 1; then
        echo
        echo "  ${GRN}${BLD}GRANTED${RST}. New state is safe, sequence $(_seq_str)"
    else
        AVAIL=("${S_AVAIL[@]}"); ALLOC=("${S_ALLOC[@]}"); NEED=("${S_NEED[@]}")   # undo
        echo
        echo "  ${RED}${BLD}DENIED${RST}: granting it would lead to an UNSAFE state. P$p must wait."
    fi
}

# ---------- data ----------
_load_example() {
    N=5; M=3
    AVAIL=(3 3 2)
    ALLOC=(0 1 0   2 0 0   3 0 2   2 1 1   0 0 2)
    MAXM=( 7 5 3   3 2 2   9 0 2   2 2 2   4 3 3)
    _recompute_need
}

_custom_input() {
    local i j r
    ask_int "Number of processes" 1 10;      N=$REPLY
    ask_int "Number of resource types" 1 6;  M=$REPLY
    AVAIL=(); ALLOC=(); MAXM=()
    for (( j = 0; j < M; j++ )); do
        ask_int "Available instances of resource $j" 0 1000; AVAIL[j]=$REPLY
    done
    for (( i = 0; i < N; i++ )); do
        echo "${CYN}  -- P$i --${RST}"
        for (( j = 0; j < M; j++ )); do
            ask_int "   Allocation of resource $j" 0 1000;               ALLOC[i*M+j]=$REPLY
            ask_int "   Max claim  of resource $j" "${ALLOC[i*M+j]}" 1000; MAXM[i*M+j]=$REPLY
        done
    done
    _recompute_need
}

demo_bankers() {
    title "DIJKSTRA'S BANKER'S ALGORITHM (DEADLOCK AVOIDANCE)"
    note "Proactive safety validation: grants allocations only if system remains SAFE."
    _load_example
    note "Loaded standard Operating Systems textbook scenario (5 Processes, 3 Resources: A, B, C)."

    local choice
    while true; do
        echo
        echo "  ${PUR}┌──${CYN} Banker's Algorithm Operations ${PUR}───────────────────────┐${RST}"
        echo "  ${PUR}│${RST}  ${GRN}1)${RST} ${BLD}Inspect State & Find Safe Sequence${RST}                  ${PUR}│${RST}"
        echo "  ${PUR}│${RST}  ${GRN}2)${RST} ${BLD}Simulate Resource Request Vector${RST}                    ${PUR}│${RST}"
        echo "  ${PUR}│${RST}  ${GRN}3)${RST} ${BLD}Enter Custom Matrices (Allocation / Max / Available)${RST} ${PUR}│${RST}"
        echo "  ${PUR}│${RST}  ${GRN}4)${RST} Reset to Default Textbook Benchmark                 ${PUR}│${RST}"
        echo "  ${PUR}│${RST}  ${GRN}5)${RST} Display Recommended Test Scenarios                  ${PUR}│${RST}"
        echo "  ${PUR}│${RST}  ${RED}0)${RST} Return to Shell                                     ${PUR}│${RST}"
        echo "  ${PUR}└────────────────────────────────────────────────────────┘${RST}"
        ask_int "Select Operation" 0 5; choice=$REPLY

        case $choice in
            1) _print_state; _report_safety ;;
            2) _print_state; echo; _request ;;
            3) _custom_input ;;
            4) _load_example; note "Reset to initial state." ;;
            5) echo
               echo "  ${CYN}${BLD}Recommended Sequential Test Requests:${RST}"
               echo "   ${GRN}1)${RST} P1 requests [1 0 2]  -> ${GRN}${BLD}GRANTED${RST} (State remains SAFE)"
               echo "   ${YEL}2)${RST} P4 requests [3 3 0]  -> ${YEL}${BLD}WAIT${RST}    (Insufficient Available resources)"
               echo "   ${RED}3)${RST} P0 requests [0 2 0]  -> ${RED}${BLD}DENIED${RST}  (Causes deadlock; state becomes UNSAFE)"
               echo "   ${RED}4)${RST} P1 requests [5 0 0]  -> ${RED}${BLD}DENIED${RST}  (Exceeds maximum declared claim)" ;;
            0) return ;;
        esac
    done
}
