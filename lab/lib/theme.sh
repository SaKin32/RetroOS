#!/usr/bin/env bash
# lib/theme.sh : colours (themes), banner and prompt of the RetroOS shell

THEME=dracula
ARROW=">"            # "arrows on" switches to a nicer arrow if your terminal can draw it

# set_theme NAME -> fills the colour variables; fails for an unknown name
set_theme() {
    case $1 in
        cyber)   C_USER=$'\033[1;36m'; C_PATH=$'\033[1;35m'; C_ARROW=$'\033[36m'; C_ACC=$'\033[36m' ;;
        retro)   C_USER=$'\033[1;32m'; C_PATH=$'\033[1;33m'; C_ARROW=$'\033[32m'; C_ACC=$'\033[33m' ;;
        matrix)  C_USER=$'\033[1;32m'; C_PATH=$'\033[32m';   C_ARROW=$'\033[1;32m'; C_ACC=$'\033[32m' ;;
        dracula) C_USER=$'\033[1;35m'; C_PATH=$'\033[1;36m'; C_ARROW=$'\033[35m'; C_ACC=$'\033[35m' ;;
        *) return 1 ;;
    esac
    C_RST=$'\033[0m'; C_ERR=$'\033[1;31m'; C_DIM=$'\033[2m'
    THEME=$1
    if [[ -n ${NO_COLOR:-} ]]; then          # plain text mode
        C_USER=''; C_PATH=''; C_ARROW=''; C_ACC=''; C_RST=''; C_ERR=''; C_DIM=''
    fi
    return 0
}

# _pc CODE -> wraps a colour code in \001 \002 so readline knows it takes no space
_pc() { printf '\001%s\002' "$1"; }

# make_prompt -> builds the text shown before every command, in $PROMPT
#   [3] user@retros ~/folder >      (the [3] only appears if the last command failed)
make_prompt() {
    local p=$PWD st=""
    [[ $p == "$HOME"* ]] && p="~${p#"$HOME"}"
    (( LAST != 0 )) && st="$(_pc "$C_ERR")[$LAST]$(_pc "$C_RST") "
    PROMPT="${st}$(_pc "$C_USER")${RS_USER}@retros$(_pc "$C_RST") "
    PROMPT+="$(_pc "$C_PATH")${p}$(_pc "$C_RST") "
    PROMPT+="$(_pc "$C_ARROW")${ARROW}$(_pc "$C_RST") "
}

# show_banner -> welcome box + small system info (like fastfetch)
show_banner() {
    local os; os="$(uname -s) $(uname -r)"
    echo "${C_ACC}"
    echo "  +--------------------------------------+"
    echo "  |      R E T R O   O S   S H E L L     |"
    echo "  |        bash edition  -  CSE210       |"
    echo "  +--------------------------------------+${C_RST}"
    echo "  ${C_ACC}|-- User  ->${C_RST} ${RS_USER}@retros"
    echo "  ${C_ACC}|-- OS    ->${C_RST} ${os}"
    echo "  ${C_ACC}|-- Shell ->${C_RST} bash ${BASH_VERSION%%(*}"
    echo "  ${C_ACC}|-- Theme ->${C_RST} ${THEME}"
    echo "  ${C_ACC}|-- Date  ->${C_RST} $(date '+%Y-%m-%d %H:%M')"
    echo "  ${C_ACC}\`-- Lab   ->${C_RST} race deadlock bankers sched pcb memory kinfo"
    echo "  ${C_DIM}Type 'help' to see all commands.${C_RST}"
    echo
}
