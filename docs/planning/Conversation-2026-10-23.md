# Conversation log 2026-10-23

Reconstructed on 2026-11-07 from the session, which started before the
session-documentation rule existed.

* **Review** of branch `rosco-minix-duart` (2 commits over `main`: the
  XR68C681 DUART model, RAM size and debug aids; illegal instructions
  taking the exception). Report in `tmp/REVIEW-rosco-minix-duart.md`:
  four bugs on the branch, older bugs, suggestions.
* **Fixed, committed, pushed by the user:**
  * Makefile dependencies (b6d5427); firmware call check, illegal exit
    132, SIGUSR1 (add6d03).
  * Older bugs: Memory (13c3dd3), terminal/input/ROM lookup/SD/traps/tick
    (42e0b22).
  * Real firmware from `../rosco-emulator/roms/rosco_m68k_010.zip`: 2.42
    booted with `-d`, 2.50.DEV did not fit (256K ROM) and then hung on a
    probe. Added the 1MB ROM (ab925ab) and bus errors with `-d`, with a
    Musashi RTE fix for the RR bit (92ac263). Both boot to the Kermit
    prompt.
  * `make check` and `R68K_ROM` (50767ff), unhandled bus error exit
    (6f7e669), README (68f2c31), `R68K_WATCH`/`R68K_RAM` (2d88190), `-O2`
    and the hook gate (9063bb1, 44aa5b0: ~10.5 s → ~0.8 s).
* **Minix:** its DUART use needs nothing more from the model; its
  `ROSCODE1.BIN` boots to login on the new r68k. Minix still built r68k
  from upstream `bac2219` plus a patch; the user merged the branch into
  `main` of maarten-boot/r68k and updates Minix themselves.
* **Options anywhere** `-d`, `-r`, `-h`, `--` (6a2c495); **ROM read-only
  unless `-w`** (58a5016).
* **SPI:** r68k has none (SD via firmware calls); the board has CS1 on
  OP7. MAME (rosco-emulator) bit-bangs SPI to its SD card but leaves OP7
  unconnected. Noted for later (Plan L1).
* **Address errors** (from the BBC BASIC session: `move.l` to an odd
  address worked under r68k): on, with the 68010 frame (24958aa). Merged.
