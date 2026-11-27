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
_CYN=$'\033[38;2;137;220;235m'   # cyan         89dceb

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

# _styled_user -> convert username to sleek small-caps font
_styled_user() {
    local str="${1:-retro}" out="" ch i
    local -A map=(
        [a]='ᴀ' [b]='ʙ' [c]='ᴄ' [d]='ᴅ' [e]='ᴇ' [f]='ꜰ' [g]='ɢ' [h]='ʜ' [i]='ɪ'
        [j]='ᴊ' [k]='ᴋ' [l]='ʟ' [m]='ᴍ' [n]='ɴ' [o]='ᴏ' [p]='ᴘ' [q]='ǫ' [r]='ʀ'
        [s]='s' [t]='ᴛ' [u]='ᴜ' [v]='ᴠ' [w]='ᴡ' [x]='x' [y]='ʏ' [z]='ᴢ'
        [A]='ᴀ' [B]='ʙ' [C]='ᴄ' [D]='ᴅ' [E]='ᴇ' [F]='ꜰ' [G]='ɢ' [H]='ʜ' [I]='ɪ'
        [J]='ᴊ' [K]='ᴋ' [L]='ʟ' [M]='ᴍ' [N]='ɴ' [O]='ᴏ' [P]='ᴘ' [Q]='ǫ' [R]='ʀ'
        [S]='s' [T]='ᴛ' [U]='ᴜ' [V]='ᴠ' [W]='ᴡ' [X]='x' [Y]='ʏ' [Z]='ᴢ'
    )
    for (( i = 0; i < ${#str}; i++ )); do
        ch="${str:i:1}"
        out+="${map[$ch]:-$ch}"
    done
    echo "$out"
}

# _banner_compact : small-window version, no cat; every line is short enough not to wrap
_banner_compact() {
    local u=$1 kernel=$2 up=$3 host=$4 cores=$5 mem=$6 ip=$7 line=$8 R=$9 B=${10}
    local styled_u; styled_u=$(_styled_user "$u")
    echo
    echo "  ${_SKY}${B}${styled_u}${R}"
    echo "  ${_DIV}${line}${R}"
    printf "  ${_CYN}■${R} %sOS%s        %s:%s RetroOS (Linux %s)\n" "$B" "$R" "$_DIV" "$R" "$(uname -m)"
    printf "  ${_CYN}■${R} %sKernel%s    %s:%s %s\n" "$B" "$R" "$_DIV" "$R" "$kernel"
    printf "  ${_CYN}■${R} %sUptime%s    %s:%s %s\n" "$B" "$R" "$_DIV" "$R" "$up"
    printf "  ${_CYN}■${R} %sShell%s     %s:%s retroos (bash %s)\n" "$B" "$R" "$_DIV" "$R" "${BASH_VERSION%%(*}"
    printf "  ${_CYN}■${R} %sCPU%s       %s:%s %s Cores Online\n" "$B" "$R" "$_DIV" "$R" "$cores"
    printf "  ${_CYN}■${R} %sMemory%s    %s:%s %s\n" "$B" "$R" "$_DIV" "$R" "$mem"
    printf "  ${_CYN}■${R} %sHost%s      %s:%s %s\n" "$B" "$R" "$_DIV" "$R" "$host"
    printf "  ${_CYN}■${R} %sIP%s        %s:%s %s\n" "$B" "$R" "$_DIV" "$R" "$ip"
    printf "  ${_CYN}■${R} %sModules%s   %s:%s 37 Interactive Simulators [CSE210]\n" "$B" "$R" "$_DIV" "$R"
    echo "  ${_DIV}${line}${R}"
    echo "  ${_PUR}${B}Welcome back, ${u}.${R}"
    echo "  ${_CYN}◆${R} $(date '+%A, %B %d %Y  %H:%M')"
    echo "  ${_AMB}◆${R} Programs must be written for people to read, not machines to execute."
    echo
}

# _term_cols -> current width of the terminal (asks the real terminal, not a stale variable)
_term_cols() {
    local c
    if [[ -t 0 ]]; then
        c=$(stty size 2> /dev/null | awk '{print $2}')
    fi
    [[ $c =~ ^[0-9]+$ ]] && (( c > 0 )) || c=$(tput cols 2> /dev/null)
    [[ $c =~ ^[0-9]+$ ]] && (( c > 0 )) || c=${COLUMNS:-80}
    echo "$c"
}

show_banner() {
    local u=${RS_USER:-retro} kernel host cores mem up ip cpu styled_u spaced i
    kernel="$(uname -s) $(uname -r)"
    host=$(hostname 2> /dev/null || echo RetroHost)
    cores=$(nproc 2> /dev/null || echo 1)
    up=$(_uptime_str)
    mem=$(awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{if(t>0) printf "%.1f / %.1f GiB",(t-a)/1048576,t/1048576; else print "Normal"}' /proc/meminfo 2> /dev/null)
    ip=$(hostname -I 2> /dev/null | awk '{print $1}'); ip=${ip:-127.0.0.1}
    cpu=$(awk -F': ' '/model name/{print $2; exit}' /proc/cpuinfo 2> /dev/null | sed -e 's/[[:space:]]\+/ /g' -e 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [[ -z "$cpu" ]] && cpu="${cores} Cores Online"
    if (( ${#cpu} > 36 )); then cpu="${cpu:0:33}..."; fi
    styled_u=$(_styled_user "$u")
    for (( i = 0; i < ${#u}; i++ )); do spaced+="${u:i:1} "; done
    spaced=${spaced^^}; spaced=${spaced% }

    local R=$'\033[0m' B=$'\033[1m'
    if [[ -n ${NO_COLOR:-} ]]; then
        R=''; B=''; _PUR=''; _COR=''; _AMB=''; _SKY=''; _MNT=''; _DIV=''; _WHT=''; _OR2=''; _CYN=''
    fi
    # How wide is the window?  Narrow window => compact banner (no cat), so nothing wraps and breaks.
    local cols; cols=$(_term_cols)
    local line; printf -v line '%*s' $(( cols > 80 ? 77 : cols - 4 )) ''; line=${line// /─}
    if (( cols < 80 )); then _banner_compact "$u" "$kernel" "$up" "$host" "$cores" "$mem" "$ip" "$line" "$R" "$B"; return; fi

    local dots=$'\033[38;2;255;255;255m● \033[38;2;137;220;235m● \033[38;2;116;199;236m● \033[38;2;137;180;250m● \033[38;2;203;166;247m● \033[38;2;251;191;36m● \033[38;2;74;222;128m● \033[38;2;244;114;182m●'

    echo
    printf '%s%s  %s%s%s%s\n'                      "$_PUR" "${CAT[1]}"  "$_SKY" "$B" "$styled_u" "$R"
    printf '%s%s  %s────────────────────────────────────────%s\n' "$_PUR" "${CAT[2]}"  "$_DIV" "$R"
    printf '%s%s  %s■%s %sOS%s        %s:%s RetroOS (Linux %s)\n' "$_PUR" "${CAT[3]}" "$_CYN" "$R" "$B" "$R" "$_DIV" "$R" "$(uname -m)"
    printf '%s%s  %s■%s %sKernel%s    %s:%s %s\n'     "$_PUR" "${CAT[4]}" "$_CYN" "$R" "$B" "$R" "$_DIV" "$R" "$kernel"
    printf '%s%s  %s■%s %sUptime%s    %s:%s %s\n'     "$_PUR" "${CAT[5]}" "$_CYN" "$R" "$B" "$R" "$_DIV" "$R" "$up"
    printf '%s%s  %s■%s %sShell%s     %s:%s retroos (bash %s)\n' "$_PUR" "${CAT[6]}" "$_CYN" "$R" "$B" "$R" "$_DIV" "$R" "${BASH_VERSION%%(*}"
    printf '%s%s  %s■%s %sCPU%s       %s:%s %s\n'     "$_PUR" "${CAT[7]}" "$_CYN" "$R" "$B" "$R" "$_DIV" "$R" "$cpu"
    printf '%s%s  %s■%s %sMemory%s    %s:%s %s\n'     "$_PUR" "${CAT[8]}" "$_CYN" "$R" "$B" "$R" "$_DIV" "$R" "$mem"
    printf '%s%s  %s■%s %sHost%s      %s:%s %s\n'     "$_PUR" "${CAT[9]}" "$_CYN" "$R" "$B" "$R" "$_DIV" "$R" "$host"
    printf '%s%s  %s■%s %sIP%s        %s:%s %s\n'     "$_PUR" "${CAT[10]}" "$_CYN" "$R" "$B" "$R" "$_DIV" "$R" "$ip"
    printf '%s%s  %s■%s %sModules%s   %s:%s 37 Interactive Simulators [CSE210]\n' "$_PUR" "${CAT[11]}" "$_CYN" "$R" "$B" "$R" "$_DIV" "$R"
    printf '%s%s\n'                                 "$_PUR" "${CAT[12]}"
    printf '%s%s  %s%s\n'                           "$_PUR" "${CAT[13]}" "$dots" "$R"
    printf '%s%s\n'                                 "$_PUR" "${CAT[14]}"
    printf '%s%s\n'                                 "$_PUR" "${CAT[15]}"
    printf '%s%s\n'                                 "$_PUR" "${CAT[16]}"
    printf '%s%s\n'                                 "$_PUR" "${CAT[17]}"
    echo
    echo "${_PUR}${B}  W E L C O M E   B A C K ,   ${spaced}${R}"
    echo "  ${_CYN}◆${R} $(date '+%A, %B %d %Y  %H:%M')"
    echo "  ${_AMB}◆${R} Programs must be written for people to read, not machines to execute."
    echo
}
