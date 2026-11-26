#!/usr/bin/env bash
# lib/ui.sh : small helpers shared by every module (colours, headings, input)

# same colours as the C shell (cyber purple theme, 24-bit colour)
RST=$'\033[0m'
RED=$'\033[38;2;248;113;113m'      # red     f87171  errors, DENIED
GRN=$'\033[38;2;52;211;153m'       # green   34d399  OK, SAFE, CORRECT
YEL=$'\033[38;2;251;191;36m'       # amber   fbbf24  prompts, WAIT
CYN=$'\033[38;2;34;211;238m'       # cyan    22d3ee  headings
PUR=$'\033[38;2;192;132;252m'      # purple  c084fc  accents
DIM=$'\033[38;2;148;163;184m'      # muted   94a3b8  explanations
BLD=$'\033[1m'
# plain text mode:  NO_COLOR=1 ./main.sh   (use it if colours look like garbage)
if [[ -n ${NO_COLOR:-} ]]; then RST=''; RED=''; GRN=''; YEL=''; CYN=''; PUR=''; DIM=''; BLD=''; fi

# title "text"  -> coloured heading
title() { echo; echo "${PUR}${BLD}=== ${CYN}$1${PUR} ===${RST}"; }

# note "text"   -> dim explanation line
note() { echo "${DIM}  $1${RST}"; }

# ask_int "prompt" LOW HIGH  -> keeps asking until a number in range is typed.
# The answer is returned in the variable $REPLY.
ask_int() {
    local prompt=$1 lo=$2 hi=$3 v
    while true; do
        printf '%s' "${YEL}${prompt} [${lo}-${hi}]: ${RST}"
        read -r v || { echo; exit 0; }          # Ctrl+D / end of input -> quit
        if [[ $v =~ ^[0-9]+$ ]] && (( v >= lo && v <= hi )); then
            REPLY=$v
            return
        fi
    done
}

# now_ms -> current time in milliseconds
now_ms() { echo $(( $(date +%s%N) / 1000000 )); }

# ---------------------------------------------------------------
# Portable lock  (a "mutex" between processes) - needs NO flock,
# so it works in Git Bash on Windows and on Linux.
#
# Idea: with 'noclobber' on, "echo > file" FAILS if the file already
# exists. Creating the file is therefore an atomic "take the lock".
# Deleting the file releases the lock.  The file also stores the owner.
# ---------------------------------------------------------------

# lock_try LOCKFILE OWNER   -> succeeds if we got the lock, fails at once if busy
lock_try() {
    local rc
    set -o noclobber
    { echo "$2" > "$1"; } 2> /dev/null
    rc=$?
    set +o noclobber
    return $rc
}

# lock_wait LOCKFILE OWNER TRIES GAP  -> keep trying every GAP seconds, up to TRIES times
lock_wait() {
    local lock=$1 who=$2 tries=$3 gap=$4 k
    for (( k = 0; k < tries; k++ )); do
        lock_try "$lock" "$who" && return 0
        sleep "$gap"
    done
    return 1
}

# lock_release LOCKFILE
lock_release() { rm -f "$1"; }

# lock_holder LOCKFILE  -> prints the owner name stored in the lock file
lock_holder() { local h="?"; read -r h < "$1" 2> /dev/null; echo "$h"; }
