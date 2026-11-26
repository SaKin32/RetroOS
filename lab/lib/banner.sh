#!/usr/bin/env bash
# lib/banner.sh : the welcome screen - purple cat on the left, system tree on the right
# (replaces the simple banner in theme.sh)

_PUR=$'\033[38;2;192;132;252m'   # cat purple   c084fc
_COR=$'\033[38;2;244;114;182m'   # system       f472b6
_AMB=$'\033[38;2;251;191;36m'    # desktop      fbbf24
_SKY=$'\033[38;2;56;189;248m'    # hardware     38bdf8
_MNT=$'\033[38;2;74;222;128m'    # palette      4ade80
_DIV=$'\033[38;2;88;91;112m'     # divider      585b70
_WHT=$'\033[38;2;255;255;255m'
_OR2=$'\033[38;2;250;179;135m'

CAT=(
    '   ⣀⣿⢷⣆⣀      ⢦⣤⢀            ⣀   '
    '  ⢀⣿⣿⣿⣿⠾⣶⡀⠶⢾⣷⣧⣴⣿⣺⡟⣦⣤⡀    ⢀⣤⣼⣿⣿   '
    '  ⢸⣿⣾⣾⣿⡐⣿⣿⣶⣄⠉⠟⣿⣿⣺⣷⣿⣿⣧⣀ ⣠⣾⣫⣿⣿⣿⣿   '
    '  ⢠⣿⣿⣿⣿⡧⣿⢹⣿⣿⢿⣿⣼⣿⢸⣿⡷⣾⡜⢻⣿⣿⣿⠹⣷⣶⣿⡟   '
    '  ⢘⣿⣿⣿⣿⠟⣿⣺⣿⣻⣟⣿⣛⣿⣺⣿⣿⣿⢺⣿⣿⣿⣿⢞⣿⣿⣿⡇   '
    '  ⠈⣿⣿⣽⣽⣇⣿⣿⣿⣿⣿⣿⣭⣿⢹⣿⣿⣿⣩⣿⣿⣿⡟⢉⢹⣿⡿⠁   '
    '   ⣛⣿⡿⠹⠋⠙⠙⢿⣻⣟⣿⣛⣯⣸⣿⣯⣿⣫⣽⣿⣿⣧⢁⣜⠻⠁    '
    ' ⡴⠼⣿⣟⣠⣼⡾⣿⣧⡄⣻⣿⣿⡿⣿⠚⠉⣁⣀⣄⡉⠹⣿⣿⡘⠛⢀⡀    '
    '  ⢀⣿⡿⠻⣿⠟⣿⣿⣏⢉⣿⣿⣿⣿⢿⡿⣿⣿⣽⣿⣤⣿⣿⢿⡿⠿⠁    '
    '  ⠰⠿⠿⠆⣠⢰⣺⢻⢿⢻⣿⣿⣿⠿⢸⣿⣟⠈⠈⠁⠛⠙⣻        '
    '      ⠉⠘⠿⢾⣶⣌⣩⣉⣉⣀⢾⣿⣿⣾⣶⡶⠶⠛⠿⠰⠦      '
    '        ⢀⡀⠈⣸⣿⣿⣯⣿⢻⣯⡥⢩⢄⣤           '
    '         ⣸⣽⣿⣿⣿⠿⠝⢋⣁⣤⣤⢬⣧⡀          '
    '        ⢠⢽⣿⣿⣿⠏⣀⣶⢼⡿⣿⣿⣽⣿⣷⣀         '
    '          ⣿⣽⣿⣀⠿ ⣸⡇⠻⢿⠟⢿⣿⣿⣆        '
    '          ⢸⣿⣟⣿⣤⣀⢈⡀ ⢠⣠⣟⣿⣟⣿⡄       '
    '          ⢸⣿⣿⣿⣿⢿⣻⡿⡇⠸⣿⣿⣿⣿⣿⡄       '
    '          ⢸⣿⣿⣿⣿⡄⢹⣿⣿⡄⢻⣿⣿⠟⠋        '
)

# _uptime_str -> "1d 2h 3m"
_uptime_str() {
    local s d h m
    s=$(awk '{print int($1)}' /proc/uptime 2> /dev/null || echo 0)
    d=$(( s / 86400 )); h=$(( s % 86400 / 3600 )); m=$(( s % 3600 / 60 ))
    if (( d > 0 )); then echo "${d}d ${h}h ${m}m"
    elif (( h > 0 )); then echo "${h}h ${m}m"
    else echo "$(( m > 0 ? m : 1 )) mins"; fi
}

# _banner_compact : small-window version, no cat; every line is short enough not to wrap
_banner_compact() {
    local u=$1 kernel=$2 up=$3 host=$4 cores=$5 mem=$6 ip=$7 spaced=$8 line=$9 R=${10} B=${11}
    echo
    echo "  ${_PUR}${B}RetroOS${R} ${_DIV}-${R} ${_MNT}${u}@retros${R}"
    echo "  ${_DIV}${line}${R}"
    printf "  ${_COR}%-8s${R} ${_WHT}%s${R}\n" "Kernel" "$kernel" "Uptime" "$up" "Shell" "retroos (bash ${BASH_VERSION%%(*})"
    printf "  ${_SKY}%-8s${R} ${_WHT}%s${R}\n" "Host" "$host" "CPU" "$cores cores" "Memory" "$mem" "IP" "$ip"
    echo "  ${_DIV}${line}${R}"
    echo "  ${_PUR}${B}Welcome back, ${u}.${R}"
    echo "  ${_DIV}Type ${_AMB}help${_DIV} | ${_SKY}demo${_DIV} | ${_PUR}theme <name>${R}"
    echo "  ${_DIV}(make the terminal wider - at least 80 columns - for the cat, then: sysinfo)${R}"
    echo
}

# _term_cols -> current width of the terminal (asks the real terminal, not a stale variable)
_term_cols() {
    local c
    c=$(stty size < /dev/tty 2> /dev/null | awk '{print $2}')
    [[ $c =~ ^[0-9]+$ ]] && (( c > 0 )) || c=$(tput cols 2> /dev/null)
    [[ $c =~ ^[0-9]+$ ]] && (( c > 0 )) || c=${COLUMNS:-80}
    echo "$c"
}

show_banner() {
    local u=${RS_USER:-retro} kernel host cores mem up ip spaced i
    kernel="$(uname -s) $(uname -r)"
    host=$(hostname 2> /dev/null || echo RetroHost)
    cores=$(nproc 2> /dev/null || echo 1)
    up=$(_uptime_str)
    mem=$(awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{if(t>0) printf "%.1f / %.1f GiB",(t-a)/1048576,t/1048576; else print "Normal"}' /proc/meminfo 2> /dev/null)
    ip=$(hostname -I 2> /dev/null | awk '{print $1}'); ip=${ip:-127.0.0.1}
    for (( i = 0; i < ${#u}; i++ )); do spaced+="${u:i:1} "; done
    spaced=${spaced^^}; spaced=${spaced% }

    local R=$'\033[0m' B=$'\033[1m'
    if [[ -n ${NO_COLOR:-} ]]; then
        R=''; B=''; _PUR=''; _COR=''; _AMB=''; _SKY=''; _MNT=''; _DIV=''; _WHT=''; _OR2=''
    fi
    # How wide is the window?  Narrow window => compact banner (no cat), so nothing wraps and breaks.
    local cols; cols=$(_term_cols)
    local line; printf -v line '%*s' $(( cols > 80 ? 77 : cols - 4 )) ''; line=${line// /─}
    if (( cols < 80 )); then _banner_compact "$u" "$kernel" "$up" "$host" "$cores" "$mem" "$ip" "$spaced" "$line" "$R" "$B"; return; fi
    local pad; printf -v pad '%*s' 35 ''      # the cat is 33 characters wide, + 2 spaces (a fixed number: bash counts bytes in the C locale)

    echo
    printf '%s%s  %s----------------------------------------%s\n' "$_PUR" "${CAT[1]}" "$_DIV" "$R"
    printf '%s%s  %so SYSTEM%s\n'                  "$_PUR" "${CAT[2]}" "$_COR" "$R"
    printf '%s%s  %s  |-- OS      -> %s%s%s\n'    "$_PUR" "${CAT[3]}" "$_COR" "$_WHT" "RetroOS (Unix/Linux $(uname -m))" "$R"
    printf '%s%s  %s  |-- Kernel  -> %s%s%s\n'    "$_PUR" "${CAT[4]}" "$_COR" "$_WHT" "$kernel" "$R"
    printf '%s%s  %s  |-- Uptime  -> %s%s%s\n'    "$_PUR" "${CAT[5]}" "$_COR" "$_WHT" "$up" "$R"
    printf '%s%s  %s  |-- Shell   -> %s%s%s\n'    "$_PUR" "${CAT[6]}" "$_COR" "$_WHT" "retroos (bash ${BASH_VERSION%%(*})" "$R"
    printf '%s%s%s\n'                              "$_PUR" "${CAT[7]}" "$R"
    printf '%s%s  %so DESKTOP%s\n'                "$_PUR" "${CAT[8]}" "$_AMB" "$R"
    printf '%s%s  %s  |-- DE      -> %s%s%s\n'    "$_PUR" "${CAT[9]}" "$_AMB" "$_WHT" "Terminal" "$R"
    printf '%s%s  %s  |-- WM      -> %s%s%s\n'    "$_PUR" "${CAT[10]}" "$_AMB" "$_WHT" "RetroOS Shell" "$R"
    printf '%s%s  %s  |-- Theme   -> %s%s%s\n'    "$_PUR" "${CAT[11]}" "$_AMB" "$_WHT" "Cyber Purple [RetroOS]" "$R"
    printf '%s%s  %s  |-- Font    -> %s%s%s\n'    "$_PUR" "${CAT[12]}" "$_AMB" "$_WHT" "Monospace" "$R"
    printf '%s%s%s\n'                              "$_PUR" "${CAT[13]}" "$R"
    printf '%s%s  %so HARDWARE%s\n'               "$_PUR" "${CAT[14]}" "$_SKY" "$R"
    printf '%s%s  %s  |-- Host    -> %s%s%s\n'    "$_PUR" "${CAT[15]}" "$_SKY" "$_WHT" "$host" "$R"
    printf '%s%s  %s  |-- CPU     -> %s%s%s\n'    "$_PUR" "${CAT[16]}" "$_SKY" "$_WHT" "$cores Cores Online" "$R"
    printf '%s%s  %s  |-- Memory  -> %s%s%s\n'    "$_PUR" "${CAT[17]}" "$_SKY" "$_WHT" "$mem" "$R"
    printf '%s%s  |-- IP      -> %s%s%s\n'      "$pad" "$_SKY" "$_WHT" "$ip" "$R"
    echo
    printf '%s%so PALETTE%s\n' "$pad" "$_MNT" "$R"
    printf '%s  \033[38;2;255;255;255m(*) \033[38;2;166;227;161m(*) \033[38;2;137;220;235m(*) \033[38;2;203;166;247m(*) \033[38;2;137;180;250m(*) \033[38;2;250;179;135m(*) \033[38;2;243;139;168m(*)%s\n' "$pad" "$R"
    echo "${_DIV}  ${line}${R}"
    echo "${_PUR}${B}  W E L C O M E   B A C K ,   ${spaced}${R}"
    echo "${_OR2}  You are not just a user behind a terminal. You are PID 1.${R}"
    echo "${_PUR}${B}  The shell is not a tool. It is your will, made executable.${R}"
    echo "${_DIV}  ${line}${R}"
    echo "  Where did you want to go, or what did you want to do?"
    echo "  ${_DIV}(Type ${_AMB}help${_DIV} for commands | ${_SKY}user <name>${_DIV} to rename | ${C_ACC}theme <name>${_DIV} to restyle)${R}"
    echo
}
