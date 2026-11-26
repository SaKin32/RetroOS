#!/usr/bin/env bash
# modules/memory.sh : "memory" command - page replacement
#
#   memory fifo 3 7 0 1 2 0 3 0 4 2 3 0 3 2     algorithm, frames, page reference string
#   memory lru  3 7 0 1 2 0 3 0 4 2 3 0 3 2
#   memory opt  3 7 0 1 2 0 3 0 4 2 3 0 3 2
#   memory compare 3 7 0 1 2 0 3 0 4 2 3 0 3 2   all three side by side
#   memory belady                                 FIFO gets WORSE with more frames
#   memory                                        quick demo
#
# A page FAULT = the page is not in RAM, so the OS must load it from disk.
# When all frames are full the OS must choose a victim page to throw out:
#   FIFO = the page that has been in memory the longest
#   LRU  = the page not used for the longest time
#   OPT  = the page that will not be needed for the longest time in the future

# _mem_run ALGO FRAMES QUIET PAGE...   -> sets MEM_FAULTS and MEM_HITS
_mem_run() {
    local algo=$1 F=$2 quiet=$3; shift 3
    local -a refs=("$@") fr=() used=()
    local n=${#refs[@]} t j k p hit idx victim ptr=0 oldest far nxt cell line
    MEM_FAULTS=0; MEM_HITS=0
    for (( j = 0; j < F; j++ )); do fr[j]=-1; used[j]=0; done

    for (( t = 0; t < n; t++ )); do
        p=${refs[t]}; hit=0; idx=-1
        for (( j = 0; j < F; j++ )); do
            if (( fr[j] == p )); then hit=1; idx=$j; fi
        done
        if (( hit )); then
            MEM_HITS=$(( MEM_HITS + 1 )); used[idx]=$(( t + 1 ))   # remember last use (for LRU)
        else
            MEM_FAULTS=$(( MEM_FAULTS + 1 ))
            victim=-1
            for (( j = 0; j < F; j++ )); do           # first use an empty frame
                if (( fr[j] == -1 )); then victim=$j; break; fi
            done
            if (( victim < 0 )); then                 # all full: choose a victim
                case $algo in
                    fifo) victim=$ptr ;;              # oldest = the one the pointer shows
                    lru)  victim=0; oldest=${used[0]}
                          for (( j = 1; j < F; j++ )); do
                              if (( used[j] < oldest )); then oldest=${used[j]}; victim=$j; fi
                          done ;;
                    opt)  victim=0; far=-1
                          for (( j = 0; j < F; j++ )); do
                              nxt=999999                # next time this page is used
                              for (( k = t + 1; k < n; k++ )); do
                                  if (( refs[k] == fr[j] )); then nxt=$k; break; fi
                              done
                              if (( nxt > far )); then far=$nxt; victim=$j; fi
                          done ;;
                esac
            fi
            fr[victim]=$p; used[victim]=$(( t + 1 ))
            if [[ $algo == fifo ]]; then ptr=$(( (victim + 1) % F )); fi
        fi
        if (( ! quiet )); then
            line=$(printf "  %-5s" "$p")
            for (( j = 0; j < F; j++ )); do
                if (( fr[j] < 0 )); then cell="-"; else cell=${fr[j]}; fi
                line+=$(printf " %3s" "$cell")
            done
            if (( hit )); then line+="   ${GRN}hit${RST}"; else line+="   ${RED}FAULT${RST}"; fi
            echo "$line"
        fi
    done
}

# _mem_summary N  -> faults, hits and ratios of the last run
_mem_summary() {
    local n=$1
    echo
    echo "  Page faults: ${RED}${BLD}${MEM_FAULTS}${RST}   Hits: ${GRN}${BLD}${MEM_HITS}${RST}   (of $n references)"
    echo "  Fault ratio: $(awk -v f=$MEM_FAULTS -v n=$n 'BEGIN{printf "%.1f%%", 100*f/n}')" \
         "  Hit ratio: $(awk -v h=$MEM_HITS -v n=$n 'BEGIN{printf "%.1f%%", 100*h/n}')"
}

_mem_check() {   # _mem_check FRAMES PAGE...
    local f=$1; shift
    if [[ ! $f =~ ^[1-9][0-9]*$ ]] || (( f > 10 )); then echo "  frames must be a number from 1 to 10"; return 1; fi
    if (( $# == 0 )); then echo "  give a page reference string, for example: 7 0 1 2 0 3 0 4"; return 1; fi
    local x
    for x in "$@"; do
        if [[ ! $x =~ ^[0-9]+$ ]]; then echo "  page numbers must be digits, got '$x'"; return 1; fi
    done
}

cmd_memory() {
    local algo=${1:-demo} F n a lbl
    local -a refs
    case $algo in
        demo)
            note "Quick demo: 3 frames, classic reference string."
            cmd_memory lru 3 7 0 1 2 0 3 0 4 2 3 0 3 2
            return ;;
        belady)
            title "BELADY'S ANOMALY"
            refs=(1 2 3 4 1 2 5 1 2 3 4 5)
            echo "  Reference string: ${refs[*]}"
            for F in 3 4; do
                _mem_run fifo $F 1 "${refs[@]}"
                echo "  FIFO with $F frames -> ${RED}${BLD}${MEM_FAULTS}${RST} page faults"
            done
            note "More frames gave MORE faults! Only FIFO can do this."
            note "LRU and OPT never show this anomaly (they are 'stack algorithms')."
            return ;;
        compare)
            shift; F=$1; shift; _mem_check "$F" "$@" || return 1
            n=$#
            title "PAGE REPLACEMENT COMPARISON  ($F frames, $n references)"
            printf "  %-6s %8s %8s %12s\n" "Algo" "Faults" "Hits" "Hit ratio"
            echo "  -----------------------------------"
            for a in fifo lru opt; do
                _mem_run $a "$F" 1 "$@"
                printf "  %-6s %8s %8s %11s%%\n" "${a^^}" "$MEM_FAULTS" "$MEM_HITS" \
                    "$(awk -v h=$MEM_HITS -v n=$n 'BEGIN{printf "%.1f", 100*h/n}')"
            done
            note "OPT is the best possible (it sees the future) - real OSes can only approximate it."
            return ;;
        fifo|lru|opt)
            shift; F=$1; shift; _mem_check "$F" "$@" || return 1
            n=$#
            case $algo in fifo) lbl="FIFO";; lru) lbl="LRU";; opt) lbl="OPT (optimal)";; esac
            title "PAGE REPLACEMENT: $lbl  ($F frames)"
            printf "  %-5s" "page"; for (( a = 1; a <= F; a++ )); do printf " %3s" "f$a"; done; echo "   result"
            echo "  ------------------------------------------"
            _mem_run "$algo" "$F" 0 "$@"
            _mem_summary "$n" ;;
        *)
            echo "  usage:"
            echo "    memory fifo|lru|opt <frames> <pages...>   e.g. memory fifo 3 7 0 1 2 0 3 0 4"
            echo "    memory compare <frames> <pages...>"
            echo "    memory belady"
            return 1 ;;
    esac
}
