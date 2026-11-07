# r68k: Plan

Work on branch `rosco-minix-duart`, merged into `main` of
github.com/maarten-boot/r68k by the user (PRs #1–#3). The DUART commit
`a3d2f10` is also in an upstream PR to roscopeco/r68k; it is published,
so fix forward, never rewrite.

## Done

| ID  | What | Spec | Commit(s) |
|-----|------|------|-----------|
| P1  | Review of the branch (`tmp/REVIEW-rosco-minix-duart.md`) | – | 2026-10-23 |
| P2  | Makefile dependencies (headers, Musashi config, ROM sources) | S9.1 | b6d5427 |
| P3  | Firmware call needs `ILLEGAL`; unhandled illegal exits 132; SIGUSR1 in both modes | S2.2, S2.4, S8.1 | add6d03 |
| P4  | Memory: byte-wise big-endian, bounds, `delete[]`, zeroed, load errors | S1.6, S6.2 | 13c3dd3 |
| P5  | Terminal, input at end, ROM lookup, SD write check, READNUM, GETUPTICKS, polled tick | S1.3, S3.3–S3.5, S4.1, S7 | 42e0b22 |
| P6  | 1MB ROM | S1.3 | ab925ab |
| P7  | Bus errors with `-d`; RTE with RR; DUART word/long access | S5.1, S5.3, S2.5 | 92ac263 |
| P8  | `make check`, `R68K_ROM` | S9.2, S1.3 | 50767ff |
| P9  | Unhandled bus error exits with 128 + SIGBUS | S5.4 | 6f7e669 |
| P10 | README | – | 68f2c31 |
| P11 | `R68K_WATCH` disassembly, `R68K_RAM` parsing | S8.4, S1.2 | 2d88190 |
| P12 | `-O2`; hook only when tracing | S9.1, S8.6 | 9063bb1, 44aa5b0 |
| P13 | Options anywhere: `-d`, `-r`, `-h`, `--` | S6 | 6a2c495 |
| P14 | ROM read-only unless `-w` | S1.4 | 58a5016 |
| P15 | Address errors, 68010 frame (reported by the BBC BASIC port) | S2.3, S2.4 | 24958aa |
| P16 | DUART console path for embedding (from bbc-basic-68k `r68k-web.patch`) | S10.1 | a3e0ce2 |
| P17 | Cycle profiler, gated on `R68K_PROF` (from `r68k-0002-cycle-profiler.patch`) | S8.5 | 7b95236 |
| P18 | `docs/planning` (this branch, `planning`) | – | 2026-11-07 |

## To do

| ID  | What | Spec | Notes |
|-----|------|------|-------|
| P19 | Push `rosco-minix-duart` (a3e0ce2, 7b95236) and `planning`; merge into `main` | – | user |
| P20 | bbc-basic-68k: drop `src68k/web/r68k-web.patch` and `mboot/patches/r68k-0002-cycle-profiler.patch` once its r68k includes P16/P17; update PORT_PLAN.md (the illegal-instruction fix is committed, `2d92829`; the kernel now sees a 68010) | S10.1, S8.5 | other project, user's call |
| P21 | Run the manual tests M3–M5 (`Tests.md`) | S10.1, S7.2, S3.3 | need `emcc`, a real terminal, a test SD image |

## Later (noted, not planned)

| ID  | What | Notes |
|-----|------|-------|
| L1  | Bit-banged SPI on the DUART pins: OP2 CS0 (SD card, SPI-mode commands over `rosco_sd.bin`), OP4 SCK, OP6 COPI, IP2 CIPO, OP7 CS1 (a second device, to be chosen). Lets the real firmware boot from the SD image. | Reference: rosco-emulator (MAME) wires OP2/4/6 and IP2 to MAME's `spi_sdcard`; OP7 is unconnected there too. |
| L2  | Flash program/erase command emulation for `-w` (SST39SF040 style), for testing a reflash. | Only when needed. |
| L3  | DUART: CR commands, counter mode, channel B input. | Minix does not need them (checked 2026-10-23). |
