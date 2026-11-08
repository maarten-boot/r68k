# Conversation log 2026-11-08

* **Report from the BBCSDL port** (BBC BASIC console edition), left in the
  r68k root as `REPORT-duart-console-input.md` and `.patch`: with `-d`,
  one typed key is lost per run.
* **Analysis:** with `-d`, the firmware console calls and `Duart::poll()`
  both read stdin. A program reading only through the firmware never
  reads the DUART, so the first byte `poll()` takes is stranded, and
  `poll()` takes no more. The diagnosis in the report is right.
* **Reproduced** on 6e0177e: a minimal echo program (read_char, printchar,
  stop at `Q`) loses `B` of `ABCDEFGHIJQ` under `-d` once it does work
  between keys (without that, all keys go within one execution slice);
  the report's BBC BASIC test lost a key on 3/3 runs.
* **Patch** checked: applies cleanly, no warnings, 5/5 and 3/3 intact,
  `make check` unchanged. User: apply it and add a test.
* **Committed** 4c6c84a: the patch plus test T47 (10/10 lose a key on the
  old build, 0/10 on the new). `make check` 47/47.
* Left: the report files (P25) and the optional SDB `0x418` (P26).
