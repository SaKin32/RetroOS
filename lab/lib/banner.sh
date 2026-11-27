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

# _code_font -> convert text to typewriter monospace code font
_code_font() {
    local str="${1:-retro}" out="" ch i
    local -A map=(
        [a]='𝚊' [b]='𝚋' [c]='𝚌' [d]='𝚍' [e]='𝚎' [f]='𝚏' [g]='𝚐' [h]='𝚑' [i]='𝚒'
        [j]='𝚓' [k]='𝚔' [l]='𝚕' [m]='𝚖' [n]='𝚗' [o]='𝚘' [p]='𝚙' [q]='𝚚' [r]='𝚛'
        [s]='𝚜' [t]='𝚝' [u]='𝚞' [v]='𝚟' [w]='𝚠' [x]='𝚡' [y]='𝚢' [z]='𝚣'
        [A]='𝙰' [B]='𝙱' [C]='𝙲' [D]='𝙳' [E]='𝙴' [F]='𝙵' [G]='𝙶' [H]='𝙷' [I]='𝙸'
        [J]='𝙹' [K]='𝙺' [L]='𝙻' [M]='𝙼' [N]='𝙽' [O]='𝙾' [P]='𝙿' [Q]='𝚀' [R]='𝚁'
        [S]='𝚂' [T]='𝚃' [U]='𝚄' [V]='𝚅' [W]='𝚆' [X]='𝚇' [Y]='𝚈' [Z]='𝚉'
        [0]='𝟶' [1]='𝟷' [2]='𝟸' [3]='𝟹' [4]='𝟺' [5]='𝟻' [6]='𝟼' [7]='𝟽' [8]='𝟾' [9]='𝟿'
    )
    for (( i = 0; i < ${#str}; i++ )); do
        ch="${str:i:1}"
        out+="${map[$ch]:-$ch}"
    done
    echo "$out"
}

# _styled_user -> wrapper for code font
_styled_user() { _code_font "$@"; }

# _rainbow_welcome -> multicolor mixed code font welcome text (spaced & prominent)
_rainbow_welcome() {
    local u="${1:-retro}" raw="W E L C O M E   B A C K   :   " i
    for (( i = 0; i < ${#u}; i++ )); do
        raw+="${u:i:1} "
    done
    raw=${raw% }
    local out="" ch code_ch idx=0
    local -a colors=(
        $'\033[38;2;243;139;168m'  # red/pink
        $'\033[38;2;250;179;135m'  # peach/orange
        $'\033[38;2;249;226;175m'  # yellow
        $'\033[38;2;166;227;161m'  # green
        $'\033[38;2;148;226;213m'  # teal
        $'\033[38;2;137;220;235m'  # cyan
        $'\033[38;2;137;180;250m'  # blue
        $'\033[38;2;203;166;247m'  # lavender
    )
    local n=${#colors[@]}
    local -A map=(
        [a]='𝚊' [b]='𝚋' [c]='𝚌' [d]='𝚍' [e]='𝚎' [f]='𝚏' [g]='𝚐' [h]='𝚑' [i]='𝚒'
        [j]='𝚓' [k]='𝚔' [l]='𝚕' [m]='𝚖' [n]='𝚗' [o]='𝚘' [p]='𝚙' [q]='𝚚' [r]='𝚛'
        [s]='𝚜' [t]='𝚝' [u]='𝚞' [v]='𝚟' [w]='𝚠' [x]='𝚡' [y]='𝚢' [z]='𝚣'
        [A]='𝙰' [B]='𝙱' [C]='𝙲' [D]='𝙳' [E]='𝙴' [F]='𝙵' [G]='𝙶' [H]='𝙷' [I]='𝙸'
        [J]='𝙹' [K]='𝙺' [L]='𝙻' [M]='𝙼' [N]='𝙽' [O]='𝙾' [P]='𝙿' [Q]='𝚀' [R]='𝚁'
        [S]='𝚂' [T]='𝚃' [U]='𝚄' [V]='𝚅' [W]='𝚆' [X]='𝚇' [Y]='𝚈' [Z]='𝚉'
        [0]='𝟶' [1]='𝟷' [2]='𝟸' [3]='𝟹' [4]='𝟺' [5]='𝟻' [6]='𝟼' [7]='𝟽' [8]='𝟾' [9]='𝟿'
        [_]='_' [:]=':'
    )
    for (( i = 0; i < ${#raw}; i++ )); do
        ch="${raw:i:1}"
        if [[ "$ch" == " " ]]; then
            out+=" "
        else
            code_ch="${map[$ch]:-$ch}"
            out+="${colors[idx % n]}${code_ch}"
            (( idx++ ))
        fi
    done
    out+=$'\033[0m'
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
    echo "  ${B}$(_rainbow_welcome "$u")${R}"
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
    styled_u=$(_styled_user "$u")

    local r_kernel="$kernel"
    if [[ "$r_kernel" =~ microsoft ]]; then
        r_kernel="Linux $(uname -r | cut -d'-' -f1) (WSL2)"
    elif (( ${#r_kernel} > 26 )); then
        r_kernel="${r_kernel:0:23}..."
    fi

    local r_cpu="$cpu"
    if (( ${#r_cpu} > 26 )); then
        r_cpu="${r_cpu:0:23}..."
    fi

    local R=$'\033[0m' B=$'\033[1m'
    local -a C_CAT=(
        ""
        $'\033[38;2;243;139;168m'  # 1: Pink/Red
        $'\033[38;2;243;139;168m'  # 2
        $'\033[38;2;250;179;135m'  # 3: Peach/Orange
        $'\033[38;2;250;179;135m'  # 4
        $'\033[38;2;249;226;175m'  # 5: Amber/Yellow
        $'\033[38;2;249;226;175m'  # 6
        $'\033[38;2;166;227;161m'  # 7: Mint/Green
        $'\033[38;2;166;227;161m'  # 8
        $'\033[38;2;148;226;213m'  # 9: Teal
        $'\033[38;2;148;226;213m'  # 10
        $'\033[38;2;137;220;235m'  # 11: Sky Blue
        $'\033[38;2;137;220;235m'  # 12
        $'\033[38;2;137;180;250m'  # 13: Soft Blue
        $'\033[38;2;137;180;250m'  # 14
        $'\033[38;2;203;166;247m'  # 15: Lavender
        $'\033[38;2;203;166;247m'  # 16
        $'\033[38;2;192;132;252m'  # 17: Violet/Purple
    )
    if [[ -n ${NO_COLOR:-} ]]; then
        R=''; B=''; _PUR=''; _COR=''; _AMB=''; _SKY=''; _MNT=''; _DIV=''; _WHT=''; _OR2=''; _CYN=''
        C_CAT=('' '' '' '' '' '' '' '' '' '' '' '' '' '' '' '' '' '')
    fi
    # How wide is the window?  Narrow window => compact banner (no cat), so nothing wraps and breaks.
    local cols; cols=$(_term_cols)
    local line; printf -v line '%*s' $(( cols > 80 ? 77 : cols - 4 )) ''; line=${line// /─}
    if (( cols < 80 )); then _banner_compact "$u" "$kernel" "$up" "$host" "$cores" "$mem" "$ip" "$line" "$R" "$B"; return; fi

    local dots=$'\033[38;2;255;255;255m● \033[38;2;137;220;235m● \033[38;2;116;199;236m● \033[38;2;137;180;250m● \033[38;2;203;166;247m● \033[38;2;251;191;36m● \033[38;2;74;222;128m● \033[38;2;244;114;182m●'

    printf '\033[?7l'   # Lock auto-wrap off to guarantee cat ASCII block never breaks
    echo
    printf '%s%s  %s%s%s%s\n'                      "${C_CAT[1]}" "${CAT[1]}"  "$_SKY" "$B" "$styled_u" "$R"
    printf '%s%s  %s──────────────────────────────────%s\n' "${C_CAT[2]}" "${CAT[2]}"  "$_DIV" "$R"
    printf '%s%s  %s■%s %sOS%s        %s:%s RetroOS (Linux %s)\n' "${C_CAT[3]}" "${CAT[3]}" "$_CYN" "$R" "$B" "$R" "$_DIV" "$R" "$(uname -m)"
    printf '%s%s  %s■%s %sKernel%s    %s:%s %s\n'     "${C_CAT[4]}" "${CAT[4]}" "$_CYN" "$R" "$B" "$R" "$_DIV" "$R" "$r_kernel"
    printf '%s%s  %s■%s %sUptime%s    %s:%s %s\n'     "${C_CAT[5]}" "${CAT[5]}" "$_CYN" "$R" "$B" "$R" "$_DIV" "$R" "$up"
    printf '%s%s  %s■%s %sShell%s     %s:%s retroos (bash %s)\n' "${C_CAT[6]}" "${CAT[6]}" "$_CYN" "$R" "$B" "$R" "$_DIV" "$R" "${BASH_VERSION%%(*}"
    printf '%s%s  %s■%s %sCPU%s       %s:%s %s\n'     "${C_CAT[7]}" "${CAT[7]}" "$_CYN" "$R" "$B" "$R" "$_DIV" "$R" "$r_cpu"
    printf '%s%s  %s■%s %sMemory%s    %s:%s %s\n'     "${C_CAT[8]}" "${CAT[8]}" "$_CYN" "$R" "$B" "$R" "$_DIV" "$R" "$mem"
    printf '%s%s  %s■%s %sHost%s      %s:%s %s\n'     "${C_CAT[9]}" "${CAT[9]}" "$_CYN" "$R" "$B" "$R" "$_DIV" "$R" "$host"
    printf '%s%s  %s■%s %sIP%s        %s:%s %s\n'     "${C_CAT[10]}" "${CAT[10]}" "$_CYN" "$R" "$B" "$R" "$_DIV" "$R" "$ip"
    printf '%s%s  %s■%s %sModules%s   %s:%s 37 Interactive Labs [CSE210]\n' "${C_CAT[11]}" "${CAT[11]}" "$_CYN" "$R" "$B" "$R" "$_DIV" "$R"
    printf '%s%s\n'                                 "${C_CAT[12]}" "${CAT[12]}"
    printf '%s%s  %s%s\n'                           "${C_CAT[13]}" "${CAT[13]}" "$dots" "$R"
    printf '%s%s\n'                                 "${C_CAT[14]}" "${CAT[14]}"
    printf '%s%s\n'                                 "${C_CAT[15]}" "${CAT[15]}"
    printf '%s%s\n'                                 "${C_CAT[16]}" "${CAT[16]}"
    printf '%s%s\n'                                 "${C_CAT[17]}" "${CAT[17]}"
    printf '\033[?7h'   # Re-enable auto-wrap
    echo
    echo "  ${B}$(_rainbow_welcome "$u")${R}"
    echo "  ${_CYN}◆${R} $(date '+%A, %B %d %Y  %H:%M')"
    echo "  ${_AMB}◆${R} Programs must be written for people to read, not machines to execute."
    echo
}
