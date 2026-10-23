#!/usr/bin/env bash
#
# r68k regression tests: tiny hand-assembled programs (loaded at 0x40000
# and run by the translator ROM), plus booting the real rosco_m68k
# firmware with -d when its ROMs are around.
#
#   tests/run.sh [path/to/r68k]
#
# R68K_REAL_ROMS: zip with the real ROMs (rosco_m68k.rom = 2.50.DEV,
# rosco_m68k_242.rom = 2.42), default ../rosco-emulator/roms/rosco_m68k_010.zip
# next to this checkout. Those tests are skipped when it is missing.

set -u

here=$(cd "$(dirname "$0")" && pwd)
r68k=$(cd "$(dirname "${1:-$here/../r68k}")" && pwd)/$(basename "${1:-r68k}")
real_roms=${R68K_REAL_ROMS:-$here/../../rosco-emulator/roms/rosco_m68k_010.zip}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work" || exit 1

passed=0
failed=0
skipped=0

ok()   { echo "ok    $1"; passed=$((passed + 1)); }
fail() { echo "FAIL  $1: $2"; failed=$((failed + 1)); }
skip() { echo "skip  $1: $2"; skipped=$((skipped + 1)); }

# bin <file> <hex>: write the program bytes
bin() {
    printf "$(echo "$2" | tr -d ' ' | sed 's/../\\x&/g')" > "$1"
}

# run <secs> <args...>: r68k with a time limit, stdout to out, stderr to err;
# sets rc
run() {
    local secs=$1
    shift
    timeout "$secs" "$r68k" "$@" > out 2> err
    rc=$?
}

# expect <name> <rc> [stdout grep] [stderr grep]
expect() {
    local name=$1 want=$2
    if [ "$rc" != "$want" ]; then
        fail "$name" "exit status $rc, expected $want"
    elif [ -n "${3:-}" ] && ! grep -q -- "$3" out; then
        fail "$name" "stdout lacks '$3'"
    elif [ -n "${4:-}" ] && ! grep -q -- "$4" err; then
        fail "$name" "stderr lacks '$4'"
    else
        ok "$name"
    fi
}

# Firmware trap: move.l #$F0F0F0nn,d7 / move.l #$AA55AA55,d6 / illegal
trap_() { echo "2e3c f0f0 f0$1 2c3c aa55 aa55 4afc"; }
EXIT=$(trap_ f3)

# --- translator ROM ------------------------------------------------------

bin exit.bin "$EXIT"
run 5 exit.bin < /dev/null
expect "exit trap" 0

# moveq #42,d0 / move.l d0,-(a7) x2 / exit: the code is at 4(a7)
bin exit42.bin "702a 2f00 2f00 $EXIT"
run 5 exit42.bin < /dev/null
expect "exit status from the stack" 42

# moveq #'H',d0 / printchar / moveq #'i',d0 / printchar / exit
bin print.bin "7048 $(trap_ f2) 7069 $(trap_ f2) $EXIT"
run 5 print.bin < /dev/null
expect "printchar trap" 0 "^Hi$"

# move.b #'A',$F00007 / move.b #10,$F00007 (THRA) / exit
bin duart.bin "13fc 0041 00f0 0007 13fc 000a 00f0 0007 $EXIT"
run 5 -d duart.bin < /dev/null
expect "-d: DUART channel A output" 0 "^A$"
run 5 duart.bin < /dev/null
if [ "$rc" = 0 ] && [ ! -s out ]; then ok "no -d: DUART not there"; else fail "no -d: DUART not there" "rc $rc, output '$(cat out)'"; fi

# -d: the ROM's memory sizing runs into bus errors past the RAM, its
# handler sets RR and returns: still has to get to the program
run 5 -d exit.bin < /dev/null
expect "-d: memory sizing with bus errors" 0

# move.l $A00000,d0: nothing there, the ROM's default bus error handler
# is in place
bin berr.bin "2039 00a0 0000 $EXIT"
run 5 -d berr.bin < /dev/null
expect "-d: bus error exits 128+SIGBUS" $((128 + $(kill -l BUS))) "" "bus error at 00A00000"
run 5 berr.bin < /dev/null
expect "no -d: no bus error" 0

# moveq #0,d7 / illegal: a real illegal instruction, the ROM's halting
# handler is still in place
bin illegal.bin "7e00 4afc"
run 5 illegal.bin < /dev/null
expect "illegal instruction exits 132" 132 "" "no handler: exiting"

# the trap magic with another illegal opcode ($4AFB) is not a trap
bin badop.bin "2e3c f0f0 f0f3 2c3c aa55 aa55 4afb"
run 5 badop.bin < /dev/null
expect "trap magic needs ILLEGAL (4AFC)" 132 "" "illegal instruction 4AFB"

# read_char / move.l d0,-(a7) x2 / exit: the character is the status
bin readchar.bin "$(trap_ f5) 2f00 2f00 $EXIT"
rc=0; echo x | timeout 5 "$r68k" readchar.bin > out 2> err || rc=$?
expect "read_char" 120
run 5 readchar.bin < /dev/null
expect "read_char at end of input" 0 "" "end of input"

# move.w #$2000,sr / move.l #10000000,d0 / 1: subq.l #1,d0 / bne 1b /
# GETUPTICKS / move.l d1,-(a7) x2 / exit: some 100Hz ticks have passed
bin ticks.bin "46fc 2000 203c 0098 9680 5380 66fc $(trap_ d8) 2f01 2f01 $EXIT"
run 30 ticks.bin < /dev/null
if [ "$rc" -ge 1 ] && [ "$rc" -le 255 ]; then ok "uptime ticks ($rc)"; else fail "uptime ticks" "exit status $rc"; fi

# bra.s *: SIGUSR1 dumps the CPU, in both modes
bin loop.bin "60fe"
for mode in "" "-d"; do
    "$r68k" $mode loop.bin < /dev/null > out 2> err &
    pid=$!
    sleep 1
    kill -USR1 $pid
    sleep 1
    kill $pid
    wait $pid 2> /dev/null
    if grep -q "PC=00040000" err; then ok "SIGUSR1 dump ${mode:-without -d}"; else fail "SIGUSR1 dump ${mode:-without -d}" "no dump"; fi
done

# move.l #$23C00000,d0 / move.l d0,$1000 / exit: the immediate looks like
# an instruction, a disassembly from 0x40 bytes back goes across the writer
bin watch.bin "203c 23c0 0000 23c0 0000 1000 $EXIT"
R68K_WATCH=1000-1004 run 5 watch.bin < /dev/null
if [ "$rc" = 0 ] && grep -q "write 4 bytes 23C00000 to 00001000 at PC 00040006" err &&
   grep -q "00040000  move.l  #\$23c00000, D0" err && grep -q "00040006  move.l  D0, \$1000" err; then
    ok "R68K_WATCH"
else
    fail "R68K_WATCH" "rc $rc, $(grep -c . err) lines on stderr"
fi

run 5 missing.bin < /dev/null
expect "missing program" 1 "" "cannot open missing.bin"

head -c 2000000 /dev/zero > big.bin
run 5 big.bin < /dev/null
expect "program too large" 1 "" "does not fit"

R68K_RAM=700K run 5 exit.bin < /dev/null
expect "bad R68K_RAM" 1 "" "R68K_RAM must be"

R68K_RAM=5MB run 5 exit.bin < /dev/null
expect "R68K_RAM with trailing garbage" 1 "" "R68K_RAM must be"

R68K_RAM=2M run 5 exit.bin < /dev/null
expect "R68K_RAM=2M" 0

# --- real firmware, -d ---------------------------------------------------

# boot <name> <rom> <greps...>: wait for the Kermit prompt (it waits
# there for ever), then check the boot messages
boot() {
    local name=$1 rom=$2
    shift 2
    R68K_ROM=$rom "$r68k" -d exit.bin < /dev/null > out 2> err &
    local pid=$! i
    for i in $(seq 100); do
        grep -q "Ready for Kermit receive" out && break
        kill -0 $pid 2> /dev/null || break
        sleep 0.1
    done
    kill $pid 2> /dev/null
    wait $pid 2> /dev/null

    for want in "Ready for Kermit receive" "$@"; do
        if ! grep -q -- "$want" out; then
            fail "$name" "no '$want' in the boot output"
            return
        fi
    done
    ok "$name"
}

if [ ! -f "$real_roms" ]; then
    skip "real firmware" "no $real_roms"
elif ! unzip -o -j -q "$real_roms" rosco_m68k_242.rom '*/rosco_m68k.rom' -d roms 2> /dev/null; then
    skip "real firmware" "cannot unzip $real_roms"
else
    boot "firmware 2.42 boots" roms/rosco_m68k_242.rom "Classic.*2\.42" "MC68010" "1048576 bytes RAM" "No IDE interface found"
    boot "firmware 2.50.DEV boots" roms/rosco_m68k.rom "Classic.*2\.50" "MC68010" "1048576 bytes RAM"
fi

echo
echo "$passed passed, $failed failed, $skipped skipped"
[ "$failed" = 0 ]
