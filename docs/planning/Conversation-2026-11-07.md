# Conversation log 2026-11-07

* **Status:** tree clean, `rosco-minix-duart` = origin, `origin/main` has
  everything up to 24958aa (PR #3).
* **Hint from another thread** (bbc-basic-68k `mboot/PORT_PLAN.md` §8:
  "r68k bug found and fixed locally … not committed"): the
  illegal-instruction fix. It is the user's commit `2d92829`, in r68k
  since before 2026-10-23; add6d03 and 24958aa build on it. The
  PORT_PLAN note and its 68020 caution are out of date (Plan P20).
* bbc-basic-68k carries two more r68k patches; both applied cleanly to
  24958aa. User: add both.
  * `src68k/web/r68k-web.patch` → a3e0ce2: DUART console path for
    `__EMSCRIPTEN__` / `R68K_HOSTED`. `-DR68K_HOSTED` compile checked; no
    `emcc` here.
  * `mboot/patches/r68k-0002-cycle-profiler.patch` → 7b95236. Changed:
    `0xFFFFF0` is only special with `R68K_PROF` set (bench.py and
    bareprof.py set it). Two tests added; `make check` 45/45.
* **docs/planning** set up on branch `planning` (per the new global
  rule): Spec.md, Plan.md, Tests.md, this log and a reconstructed log for
  2026-10-23.
* **Shift timing** (report from the bbc-basic-68k profiling thread, its
  P13): immediate-count shifts were charged 2n twice, once by the opcode
  table builder and once by the handler. Confirmed with R68K_PROF
  (lsl.w #8 38, lsr.w #1 10, lsl.l #8 40). Removed the table-builder
  addition (all 24 handlers charge shift<<CYC_SHIFT themselves; rol.b and
  ror.b as orig_shift) → 22, 8, 24 (6e0177e). New test T46, which fails
  on the old build. `make check` 46/46. bbc-basic-68k must drop its
  `leprof.py` correction when it picks this up (Plan P23).
* Pushed (`rosco-minix-duart`, `planning`) and merged into `main` by the
  user: P19 done.
