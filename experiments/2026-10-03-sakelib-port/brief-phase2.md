# Brief, phase 2: rewrite the ported libraries with Sake's new features

The libraries in `sakelib/` (repo `/home/ko1/app/sake`) were ported from Ruby's standard library in
phase 1 (`experiments/2026-10-03-sakelib-port/brief.md`; notes in `sakelib/notes/`; requests summed up in
`experiments/2026-10-03-sakelib-port/builtin-requests.md`). Since then Sake gained (see `docs/spec.md`
and `docs/builtins.md`):

- **Optional positional parameters**: `def crc32(s, crc = 0)`, as in Ruby (defaults evaluated at the
  call; trailing only; no keyword arguments yet, so options Records stay).
- **`once { ... }`**: a value computed once per place in the program (`def table = once { ... }`), in
  place of value constants.
- **Built-ins**: `String.index(s, t, start)`, `String.rindex(s, t, start)`, `Regexp.match(re, s, pos)` and
  `String.match(s, re, pos)` (with `\G` anchoring at pos), `match?` with pos, `String.byteindex`,
  `String.byteslice`, `String.b`, `String.unpack` / `unpack1`, `String.sub` / `gsub` with a Hash or a
  block, `warn`, `exit`, `ARGV`, `File.delete`, `Array.pack`, `String.force_encoding`.

Your job, for each library of your group:

1. Rewrite it to use these where they make the code closer to Ruby's API, shorter, or faster:
   - Restore Ruby's single names where an extra name only existed for a missing optional argument
     (`crc32_with(s, crc)` → `crc32(s, crc = 0)`, `next_day(n = 1)`, ...). Keep the old name as an
     alias only if removing it would break the tests; otherwise remove it.
   - Build constant tables with `once`.
   - Replace character-by-character scans and string copies with the position built-ins.
2. Keep the tests passing: `ruby -Ilib test/test_sakelib.rb -n /<lib>/` (the .sake under --strict
   must print what the .rb prints). Update the tests to call the Ruby-shaped API; extend them for
   the restored optional arguments.
3. Measure speed before and after on one representative input per library (bin/sake on a small
   bench script; CPU time via `/usr/bin/time` or Ruby's Process.clock_gettime around the run; 3 runs;
   the machine is shared, so report the spread). Keep the bench scripts in
   `experiments/2026-10-03-sakelib-port/phase2/`.
4. Update `sakelib/notes/<lib>.md`: the API table (what is now "same"), what still differs, and a short
   "Phase 2" section with the changes and the speed numbers.

Rules: do not change `lib/`, `docs/`, `test/test_*.rb`, or other groups' files. If a new built-in
misbehaves, keep a minimal repro in `sakelib/notes/<lib>_bug_*.sake` and work around it. Shell commands
need `dangerouslyDisableSandbox: true`. Budget about 60 minutes. Reply with under 200 words: what
changed per library (names restored, tables, scans), speed before/after, and remaining gaps.
