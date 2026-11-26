#!/usr/bin/env bash
# =====================================================================
#  RetroOS Shell  (bash edition)
#
#  Run it with:        bash retroos.sh
#  One command only:   bash retroos.sh -c "sched rr 2 0:5 1:3 2:8"
#
#  How it works (the main loop of every shell):
#     1. show the prompt       2. read a line       3. run it       4. repeat
#  Pipes, redirects, & && || ; $(...) and variables are done by bash itself.
#  Our own commands (sched, memory, pcb, race ...) are shell FUNCTIONS
#  that live in lab/modules, so they also work inside pipes.
# =====================================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB="$DIR/lab"

# ---------- load libraries and modules ----------
source "$LAB/lib/ui.sh"          # colours, title/note, ask_int, locks
source "$LAB/lib/theme.sh"       # themes, prompt, banner
source "$LAB/lib/banner.sh"      # purple cat welcome screen
for _m in sched race deadlock bankers pcb memory sysinfo forkdemo demo; do
    source "$LAB/modules/$_m.sh"
done
unset _m

# ---------- user name ----------
USERFILE="$HOME/.retroos_user"
if [[ -r $USERFILE ]]; then read -r RS_USER < "$USERFILE"; fi
RS_USER=${RS_USER:-${USER:-user}}
LAST=0                           # exit status of the last command (shown in the prompt)
set_theme "$THEME"

# ---------- commands of RetroOS (functions, so pipes work with them) ----------
sched()        { cmd_sched "$@"; }
race()         { demo_race; }
deadlock()     { demo_deadlock; }
bankers()      { demo_bankers; }
pcb()          { cmd_pcb "$@"; }
memory()       { cmd_memory "$@"; }
meminfo()      { cmd_meminfo; }
kinfo()        { cmd_kinfo; }
monitor()      { cmd_monitor "$@"; }
trace()        { cmd_trace "$@"; }
forkdemo()     { cmd_forkdemo; }
demo()         { cmd_demo; }
sysinfo()      { show_banner; }
mode-switch()  { cmd_modeswitch; }

theme() {
    if [[ -z $1 ]]; then echo "  themes: cyber retro matrix dracula   (now: $THEME)"; return 0; fi
    if set_theme "$1"; then echo "  ${C_ACC}Theme changed to '$1'.${C_RST}"
    else echo "  unknown theme '$1'. Try: cyber retro matrix dracula"; return 1; fi
}

user() {
    if [[ -z $1 ]]; then echo "  user name: $RS_USER"; return 0; fi
    RS_USER=$1; echo "$RS_USER" > "$USERFILE"; echo "  user name is now '$RS_USER'"
}

help() {
    local -a rows=(
        "SHELL^"
        "cd, ls, pwd, history, jobs, kill^normal shell commands (any Linux program works)"
        "cmd1 | cmd2   cmd > file^pipes and redirects; also  &  &&  ||  ;  and variables"
        "alias, unalias, export^aliases and environment variables"
        "theme <name>^cyber, retro, matrix, dracula (purple)"
        "user [name]^show or change your user name"
        "help, exit^this list / leave the shell"
        "CPU SCHEDULING AND PROCESSES^"
        "sched fcfs|sjf|prio|rr ...^scheduling with Gantt chart, e.g. sched rr 2 0:5 1:3 2:8"
        "sched compare 0:5 1:3 2:8^all algorithms side by side"
        "pcb  |  pcb <pid>^the real Process Control Block from the kernel"
        "pcb sim [q] 0:5 1:3^process states tick by tick (New/Ready/Running/Done)"
        "forkdemo^fork, exec, wait, pipe, zombie and signal with real PIDs"
        "SYNCHRONIZATION^"
        "race^race condition with and without a lock"
        "deadlock^deadlock, prevention and the 4 conditions"
        "bankers^Banker's algorithm (deadlock avoidance)"
        "MEMORY AND KERNEL^"
        "memory fifo|lru|opt 3 7 0 1 2^page replacement; also: memory compare / memory belady"
        "meminfo, monitor [n]^RAM info / live CPU and RAM bars"
        "kinfo, sysinfo^kernel information / welcome banner"
        "trace <cmd>^system calls of any program (strace)"
        "mode-switch^toggle simulated Ring 3 (user) <-> Ring 0 (kernel)"
        "demo^runs everything above, one part at a time"
    )
    local r
    echo
    for r in "${rows[@]}"; do
        if [[ ${r##*^} == "" ]]; then
            echo; echo "${C_ACC}${r%^}${C_RST}"
        else
            printf "  ${YEL}%-30s${RST} ${DIM}%s${RST}\n" "${r%%^*}" "${r#*^}"
        fi
    done
    echo
}

# bash calls this for an unknown command: our own friendly error
command_not_found_handle() {
    echo "${C_ERR}retroos: $1: command not found${C_RST}  ${C_DIM}(type 'help')${C_RST}" >&2
    return 127
}

# ---------- run one line: check syntax, ask for more lines if unfinished ----------
# sets REPLY_LINE to the (possibly extended) line; returns 1 if it is not runnable
_complete_line() {
    local line=$1 err more
    while true; do
        if err=$(bash -n <<< "$line" 2>&1); then REPLY_LINE=$line; return 0; fi
        if [[ $err == *"unexpected end of file"* || $err == *"unexpected EOF"* ]]; then
            if [[ -t 0 ]]; then
                read -e -r -p "${C_DIM}> ${C_RST}" more || return 1
                line+=$'\n'"$more"
            else
                echo "${C_ERR}retroos: incomplete command${C_RST}" >&2; return 1
            fi
        else
            echo "${C_ERR}retroos: syntax error${C_RST} ${C_DIM}(${err##*: })${C_RST}" >&2
            LAST=2; return 1
        fi
    done
}

run_line() {
    local line=$1
    [[ -z ${line//[[:space:]]/} ]] && return 0
    _complete_line "$line" || return 0
    eval "$REPLY_LINE"
    LAST=$?
}

# ---------- start-up ----------
shopt -s expand_aliases          # so that 'alias ll="ls -l"' works inside the shell

if [[ $1 == -c ]]; then          # one-shot mode: bash retroos.sh -c "command"
    run_line "$2"
    exit $LAST
fi

if [[ ! -t 0 ]]; then            # commands come from a pipe or a file
    while IFS= read -r line; do run_line "$line"; done
    exit $LAST
fi

# ---------- interactive shell ----------
HISTFILE="$HOME/.retroos_history"
HISTSIZE=1000
set -o history
history -r 2> /dev/null
set -m                           # job control: jobs, fg, bg, kill %1
trap 'echo' INT                  # Ctrl+C stops the running program, not the shell
trap 'history -w' EXIT           # save the history when we leave

# Zoom in/out or resize the window: text already printed cannot be re-laid-out by the terminal,
# so while the welcome banner is still the only thing on screen we simply draw it again
# (compact version for a narrow window, full cat for a wide one).
BANNER_FRESH=1
_on_resize() {
    (( BANNER_FRESH )) || return 0
    printf '\033[H\033[2J\033[3J'   # wipe screen AND scrollback, so old copies do not pile up
    show_banner
    printf '%s' "$PROMPT"
}
trap '_on_resize' WINCH

cd "$HOME" || true
show_banner

while true; do                   # ===== the main loop =====
    make_prompt
    read -e -r -p "$PROMPT" line
    rc=$?
    if (( rc > 128 )); then echo; continue; fi         # Ctrl+C at the prompt
    if (( rc != 0 )); then echo; echo "  ${C_DIM}bye!${C_RST}"; break; fi   # Ctrl+D
    [[ -z ${line//[[:space:]]/} ]] && continue
    history -s "$line"
    BANNER_FRESH=0               # something else is on screen now: do not redraw the banner
    run_line "$line"
done

