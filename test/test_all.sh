#!/usr/bin/env bash
# ==============================================================================
#  RetroOS Automated Verification & Regression Test Suite
# ==============================================================================
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

PASSED=0
FAILED=0

C_RST=$'\033[0m'
C_GRN=$'\033[38;2;166;227;161;1m'
C_RED=$'\033[38;2;243;139;168;1m'
C_CYN=$'\033[38;2;137;220;235;1m'
C_YEL=$'\033[38;2;249;226;175;1m'
C_BLD=$'\033[1m'

# Helper to strip ANSI codes for regex assertions
strip_ansi() {
    sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g'
}

report_pass() {
    PASSED=$(( PASSED + 1 ))
    printf "  ${C_GRN}[PASS]${C_RST} %-52s\n" "$1"
}

report_fail() {
    FAILED=$(( FAILED + 1 ))
    printf "  ${C_RED}[FAIL]${C_RST} %-52s\n" "$1"
    echo "         Reason: $2"
}

echo
echo "${C_CYN}╔════════════════════════════════════════════════════════════════╗${C_RST}"
echo "${C_CYN}║       RetroOS Shell Automated CI/CD Regression Test Suite      ║${C_RST}"
echo "${C_CYN}╚════════════════════════════════════════════════════════════════╝${C_RST}"
echo

# ------------------------------------------------------------------------------
# Test 1: Syntax Validation (bash -n)
# ------------------------------------------------------------------------------
echo "${C_YEL}▶ [1/6] Validating Bash Syntax across all Scripts...${C_RST}"
SYNTAX_ERR=0
for f in retroos.sh lab/lib/*.sh lab/modules/*.sh; do
    if bash -n "$f" 2>/dev/null; then
        :
    else
        report_fail "Syntax: $f" "Bash syntax error detected"
        SYNTAX_ERR=1
    fi
done
if (( SYNTAX_ERR == 0 )); then
    report_pass "All Shell Scripts passed bash -n compilation"
fi

# ------------------------------------------------------------------------------
# Test 2: CPU Scheduling Algorithms (sched.sh)
# ------------------------------------------------------------------------------
echo "${C_YEL}▶ [2/6] Verifying CPU Scheduling Algorithms & Metrics...${C_RST}"
OUT_RR=$(bash retroos.sh -c "sched rr 2 0:5 1:3 2:8" 2>&1 | strip_ansi)
if [[ $OUT_RR =~ 11\.33.*ms ]] && [[ $OUT_RR =~ 6\.00.*ms ]]; then
    report_pass "Round Robin (q=2): Exact TAT (11.33ms) & WT (6.00ms)"
else
    report_fail "Round Robin" "Expected TAT 11.33ms and WT 6.00ms"
fi

OUT_CMP=$(bash retroos.sh -c "sched compare 0:5:2 1:3:3 2:8:1 3:2:4" 2>&1 | strip_ansi)
if [[ $OUT_CMP == *"FCFS"* ]] && [[ $OUT_CMP == *"SJF"* ]] && [[ $OUT_CMP =~ [Rr]ound[[:space:]]+[Rr]obin ]]; then
    report_pass "Scheduling Benchmark: 4 algorithms comparative analysis"
else
    report_fail "Scheduling Benchmark" "Missing comparison table output"
fi

# ------------------------------------------------------------------------------
# Test 3: Process Lifecycle & PCB Simulation (pcb.sh & forkdemo.sh)
# ------------------------------------------------------------------------------
echo "${C_YEL}▶ [3/6] Verifying Process Control Block & Lifecycle Engine...${C_RST}"
OUT_PCB=$(bash retroos.sh -c "pcb sim 2 0:3 1:2" 2>&1 | strip_ansi)
if [[ $OUT_PCB == *"PCB"* ]] && [[ $OUT_PCB == *"Terminated"* ]] && [[ $OUT_PCB == *"Summary Table"* ]]; then
    report_pass "PCB Discrete State Machine: Full lifecycle dispatch"
else
    report_fail "PCB Simulation" "Did not complete state transitions"
fi

# ------------------------------------------------------------------------------
# Test 4: Deadlock & Banker's Safety Algorithm (bankers.sh & deadlock.sh)
# ------------------------------------------------------------------------------
echo "${C_YEL}▶ [4/6] Verifying Deadlock Detection & Banker's Algorithm...${C_RST}"
OUT_BANK=$(printf '1\n0\n' | bash retroos.sh -c "bankers" 2>&1 | strip_ansi)
if [[ $OUT_BANK == *"<P1, P3, P0, P2, P4>"* ]] && [[ $OUT_BANK == *"SYSTEM IS IN A SAFE STATE"* ]]; then
    report_pass "Banker's Algorithm: Identified Safe Sequence <P1, P3, P0, P2, P4>"
else
    report_fail "Banker's Algorithm" "Safe sequence mismatch or unsafe state"
fi

# ------------------------------------------------------------------------------
# Test 5: Virtual Memory & Belady's Anomaly (memory.sh)
# ------------------------------------------------------------------------------
echo "${C_YEL}▶ [5/6] Verifying Virtual Memory Paging & Belady's Anomaly...${C_RST}"
OUT_BELADY=$(bash retroos.sh -c "memory belady" 2>&1 | strip_ansi)
if [[ $OUT_BELADY =~ FIFO.*3.*frames.*9.*page.*faults ]] && \
   [[ $OUT_BELADY =~ FIFO.*4.*frames.*10.*page.*faults ]]; then
    report_pass "Belady's Anomaly: Verified FIFO 3 frames (9) vs 4 frames (10)"
else
    report_fail "Belady's Anomaly" "Page fault counts did not match expected"
fi

OUT_MEMCMP=$(bash retroos.sh -c "memory compare 3 7 0 1 2 0 3 0 4 2 3 0 3 2" 2>&1 | strip_ansi)
if [[ $OUT_MEMCMP == *"FIFO"* ]] && [[ $OUT_MEMCMP == *"LRU"* ]] && [[ $OUT_MEMCMP == *"OPT"* ]]; then
    report_pass "Page Replacement Comparison: Multi-policy benchmark"
else
    report_fail "Memory Compare" "Comparison table missing"
fi

# ------------------------------------------------------------------------------
# Test 6: Kernel & Telemetry Modules (sysinfo.sh)
# ------------------------------------------------------------------------------
echo "${C_YEL}▶ [6/6] Verifying System Telemetry & Hardware Interface...${C_RST}"
OUT_MEMINFO=$(bash retroos.sh -c "meminfo" 2>&1 | strip_ansi)
if [[ $OUT_MEMINFO == *"VIRTUAL MEMORY TELEMETRY"* ]] && [[ $OUT_MEMINFO == *"RAM Utilization:"* ]]; then
    report_pass "Virtual Memory Telemetry: RAM Utilization progress bar"
else
    report_fail "Meminfo Telemetry" "Meminfo output incomplete"
fi

OUT_KINFO=$(bash retroos.sh -c "kinfo" 2>&1 | strip_ansi)
if [[ $OUT_KINFO == *"KERNEL ARCHITECTURE & TELEMETRY"* ]] && [[ $OUT_KINFO == *"Kernel Privilege Trapping Hierarchy"* ]]; then
    report_pass "Kernel Telemetry: CPU Ring and Privilege Trapping"
else
    report_fail "Kinfo Telemetry" "Kinfo output incomplete"
fi

# ------------------------------------------------------------------------------
# Final Verification Summary
# ------------------------------------------------------------------------------
echo
echo "${C_CYN}────────────────────────────────────────────────────────────────${C_RST}"
TOTAL=$(( PASSED + FAILED ))
if (( FAILED == 0 )); then
    echo "  ${C_GRN}${C_BLD}✔ ALL $PASSED TESTS PASSED SUCCESSFULLY (100% PASS RATE)${C_RST}"
    echo "${C_CYN}────────────────────────────────────────────────────────────────${C_RST}"
    echo
    exit 0
else
    echo "  ${C_RED}${C_BLD}✘ $FAILED OF $TOTAL TESTS FAILED${C_RST}"
    echo "${C_CYN}────────────────────────────────────────────────────────────────${C_RST}"
    echo
    exit 1
fi
