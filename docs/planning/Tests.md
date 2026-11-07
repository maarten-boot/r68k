# r68k: Tests

Each test traces to a `Spec.md` item. The automated ones are in
`tests/run.sh` (`make check`), under the names given. Status as of
2026-11-07, r68k `6e0177e`: all 46 automated tests pass.

## Automated (`make check`)

| ID  | Spec | Test name in `tests/run.sh` | Status |
|-----|------|-----------------------------|--------|
| T1  | S3.1 | exit trap | pass |
| T2  | S3.2 | exit status from the stack | pass |
| T3  | S3.1 | printchar trap | pass |
| T4  | S5.1 | -d: DUART channel A output | pass |
| T5  | S4.2 | no -d: DUART not there | pass |
| T6  | S5.3, S2.5 | -d: memory sizing with bus errors | pass |
| T7  | S5.4, S2.4 | -d: bus error exits 128+SIGBUS | pass |
| T8  | S4.2 | no -d: no bus error | pass |
| T9  | S2.3, S2.4 | address error: move.l to an odd address | pass |
| T10 | S2.3 | -d: address error too | pass |
| T11 | S2.3 | address error: move.w from an odd address | pass |
| T12 | S2.3 | address error: odd PC | pass |
| T13 | S2.3 | byte at an odd address is fine | pass |
| T14 | S2.3 | address error handler gets a format 8 frame | pass |
| T15 | S2.2, S2.4 | illegal instruction exits 132 | pass |
| T16 | S2.2 | trap magic needs ILLEGAL (4AFC) | pass |
| T17 | S3.1 | read_char | pass |
| T18 | S3.5 | read_char at end of input | pass |
| T19 | S4.1, S3.4 | uptime ticks | pass |
| T20 | S8.1 | SIGUSR1 dump without -d | pass |
| T21 | S8.1 | SIGUSR1 dump -d | pass |
| T22 | S8.4 | R68K_WATCH | pass |
| T23 | S8.3, S8.6 | R68K_DUMPAT | pass |
| T24 | S1.4 | ROM read-only | pass |
| T25 | S1.4, S5.3 | -d: ROM read-only, no bus error | pass |
| T26 | S1.4 | -w: ROM writable | pass |
| T27 | S6.1 | -d after the binary | pass |
| T28 | S6.1, S1.3 | -r <rom> | pass |
| T29 | S6.1 | -r<rom> after the binary | pass |
| T30 | S1.3 | -r over R68K_ROM | pass |
| T31 | S6.2 | -r with a missing ROM | pass |
| T32 | S6.1 | -- ends the options | pass |
| T33 | S6.2 | unknown option | pass |
| T34 | S6.2 | two binaries | pass |
| T35 | S6.2 | -r without a file | pass |
| T36 | S6.3 | -h | pass |
| T37 | S8.5, S8.6 | R68K_PROF profile | pass |
| T38 | S8.5, S5.3 | -d without R68K_PROF: 0xFFFFF0 is a bus error | pass |
| T46 | S2.6, S8.5 | shift cycles (immediate and register count): lsl.w #8 22, lsr.w #1 8, lsl.l #8 24, rol.b #3 12, lsl.l d1,d0 (8) 24 | pass (fails before 6e0177e with 38, 10, 40, 18, 24) |
| T39 | S6.2 | missing program | pass |
| T40 | S6.2, S1.6 | program too large | pass |
| T41 | S1.2, S6.2 | bad R68K_RAM | pass |
| T42 | S1.2, S6.2 | R68K_RAM with trailing garbage | pass |
| T43 | S1.2 | R68K_RAM=2M | pass |
| T44 | S5.5, S1.3 | firmware 2.42 boots | pass (needs the ROM zip) |
| T45 | S5.5, S1.3 | firmware 2.50.DEV boots | pass (needs the ROM zip) |

## Manual

| ID  | Spec | Test | Status |
|-----|------|------|--------|
| M1  | S5.1, S5.2, S2.3, S5.3 | Minix `ROSCODE1.BIN` (minix-st-2.0.4) with `-d` and `R68K_RAM=5M`: boots to `rosco login:`, `root` logs in, `ls /` lists `bin dev etc mnt tmp usr` | pass (2026-10-23, after the address errors) |
| M2  | S10.1 | `g++ -DR68K_HOSTED -c machine/Duart.cpp` compiles | pass (2026-11-07) |
| M3  | S10.1 | Emscripten build of the web page (bbc-basic-68k `src68k/web`) | not run here (no `emcc`) |
| M4  | S7.2 | Ctrl-C in a real terminal: the shell echoes normally afterwards | not run (no terminal in the session) |
| M5  | S3.3 | SD write then read back on a real `rosco_sd.bin` | not run |
| M6  | S9.1 | Touch `include/Duart.h` / `musashi/m68kconf.h`: only the dependent objects rebuild; a no-op `make` does not relink | pass (2026-10-23) |
| M7  | S8.6 | 40M-iteration loop: ~0.65–0.8 s with `-O2` and tracing off (was ~10.5 s unoptimised) | pass (2026-10-23) |
