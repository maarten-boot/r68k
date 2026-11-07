# r68k: Spec

What r68k does, as of `6e0177e` (2026-11-07). Each item has an ID that
`Tests.md` and `Plan.md` refer to. Where the code is the reference, the
file is named.

## S1 Program and memory

- **S1.1** The program file is loaded at `0x40000` and run by r68k's own
  small firmware (`firmware/`, the "translator" ROM).
- **S1.2** RAM is at `0` up to the RAM size: 1MB by default, or
  `R68K_RAM` (a multiple of 512K, 512K to 14M, with a `K` or `M` suffix and
  nothing after it).
- **S1.3** The ROM window is `0xE00000`–`0xEFFFFF` (1MB, like the v2.x
  boards' flash). The image is taken from `-r <rom>`, else `R68K_ROM`,
  else `firmware/rosco_m68k.rom` next to the r68k executable (found via
  `/proc/self/exe`, then `argv[0]`, then `.`).
- **S1.4** The ROM is read-only: writes to it are ignored, with no bus
  error. `-w` makes it writable as plain memory. The flash chip's program
  and erase commands are not emulated.
- **S1.5** At reset the first two long reads (SSP, PC) come from the ROM.
- **S1.6** Memory is big-endian, built byte by byte (no misaligned host
  access), and an access straddling the end of RAM is split.

## S2 CPU (Musashi, 68010)

- **S2.1** The CPU is a 68010.
- **S2.2** `ILLEGAL` (`0x4AFC`) with `D7 = 0xF0F0F0xx` and
  `D6 = 0xAA55AA55` is a firmware call (S3). Any other illegal opcode,
  including other opcodes with that magic in D7/D6, takes vector 4.
- **S2.3** A word or long access at an odd address, or an odd PC, is an
  address error: vector 3, with a 68010 format 8 frame and the
  instruction's register effects undone. Byte accesses may be anywhere.
- **S2.4** When the vector is still the ROM's default handler (which halts
  for ever), r68k reports and exits instead:
  - illegal instruction: 132 (128 + SIGILL);
  - address error: 128 + SIGBUS;
  - bus error (with `-d`, S5.4): 128 + SIGBUS.
- **S2.5** `RTE` from a format 8 frame with the RR bit set (the handler
  did the faulted cycle) resumes after the faulting instruction.
- **S2.6** Cycle counts follow the 68010 tables. Shifts and rotates by an
  immediate count cost 6 + 2n (byte, word) or 8 + 2n (long), charged
  once, as do shifts by a register count.

## S3 Firmware calls (translator ROM)

- **S3.1** print, println, printchar, check_char, read_char and exit
  (calls 0–5).
- **S3.2** exit takes the exit status from the stack (`4(a7)`).
- **S3.3** SD card: init, read and write of 512-byte blocks (calls 6–8),
  on the file `rosco_sd.bin` in the current directory, if it exists.
  Offsets are 64-bit. Write success is checked after write and flush.
- **S3.4** Easy68k calls `0xD0`–`0xE4`. GETUPTICKS returns the long at
  `0x40C`; READNUM reads at most 10 characters.
- **S3.5** read_char at end of input prints a message and exits with 0.

## S4 Without `-d`

- **S4.1** A 100Hz tick on vector `0x45`, polled in the main loop.
- **S4.2** Unmapped accesses are ignored (reads give 0). There is no DUART.

## S5 With `-d`

- **S5.1** An XR68C681 DUART at `0xF00000` (registers on the odd bytes;
  word and long accesses go through the byte registers). Channel A is
  stdin/stdout, channel B transmit goes to stderr.
- **S5.2** The counter/timer runs in real time; the interrupt is level
  triggered on IPL 4, with the vector from IVR.
- **S5.3** A CPU access where nothing is mapped (RAM, ROM, DUART) is a bus
  error. r68k's own memory reads (firmware calls, debug aids,
  disassembler) never are. A bus error while stacking one halts the CPU,
  and r68k exits with 1.
- **S5.4** An unhandled bus error exits with 128 + SIGBUS (S2.4).
- **S5.5** The real rosco_m68k firmware 2.42 and 2.50.DEV boot to
  "Ready for Kermit receive" (`-d -r <rom>`).

## S6 Command line

- **S6.1** `r68k [-d] [-r <rom>] [-w] [-h] <binary>`: the options may come
  before or after the binary; `--` ends them; `-r<rom>` also works.
- **S6.2** Errors exit with 1: an unknown option, a second binary, `-r`
  without a file, a program or ROM that cannot be opened or does not fit,
  a bad `R68K_RAM`.
- **S6.3** `-h` prints the usage and exits with 0; no arguments print it
  and exit with 1.

## S7 Terminal

- **S7.1** stdin is put in raw mode (no echo, no line buffering) when it
  is a terminal, and stays blocking.
- **S7.2** The terminal is restored at every exit, and on SIGINT, SIGTERM
  and SIGHUP.

## S8 Debugging aids

- **S8.1** SIGUSR1 dumps the registers, the next instructions and the PC
  trace to stderr, and the RAM to `r68k-ram.bin`, with and without `-d`.
- **S8.2** `R68K_TRACE`: keeps the last 4096 PCs for that dump, frozen at
  the first odd PC, PC outside RAM/ROM, or two zero opcodes in a row.
- **S8.3** `R68K_DUMPAT=<hex pc>`: the same dump, the first time the PC
  gets there.
- **S8.4** `R68K_WATCH=lo-hi[,plo-phi]`: the first 8 writes into
  `[lo, hi)`, with the writer's PC; the code around the first writer is
  disassembled from an instruction boundary.
- **S8.5** `R68K_PROF=<file>`: the program writes the byte 1 to
  `0xFFFFF0` to start and 2 to stop profiling; cycles and instruction
  counts per address in RAM are appended to the file. Without it,
  `0xFFFFF0` is not special.
- **S8.6** The per-instruction hook costs only a flag test unless
  `R68K_TRACE`, `R68K_DUMPAT` or `R68K_PROF` is set.

## S9 Build and tests

- **S9.1** Built with `-O2`. Header and Musashi configuration changes
  rebuild what depends on them; the ROM is rebuilt only when its sources
  change (a prebuilt ROM works without the m68k toolchain).
- **S9.2** `make check` runs `tests/run.sh`: small hand-assembled
  programs (no m68k toolchain needed), plus the real-firmware boots when
  the ROM zip is there (`R68K_REAL_ROMS`, default
  `../rosco-emulator/roms/rosco_m68k_010.zip`).

## S10 Embedding

- **S10.1** `machine/Duart.cpp` has a console path for embedding programs
  with their own `main()`: a web page (`__EMSCRIPTEN__`) or a hosted
  console program (`-DR68K_HOSTED`, providing `r68k_host_output()`).
  Channel A output is collected for `r68k_flush()`, keys come in through
  `r68k_key()` (at most one per millisecond), and up to 10 missed timer
  ticks are made up. Used by bbc-basic-68k (`src68k/web`, `src68k/host`).
