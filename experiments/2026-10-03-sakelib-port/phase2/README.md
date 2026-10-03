# Phase 2: the ported libraries rewritten with optional parameters, `once` and the position built-ins

Date: 2026-10-03. Brief: `../brief-phase2.md`. Base commit: af197cd (plus the two built-in fixes committed
with this phase: broken UTF-8 in a regexp built-in raises a catchable ArgumentError; `ARGV` is one Array).

Method: four agents, one group each, rewrote `sakelib/*.sake`, extended `test/sakelib/*` (outputs still
identical to Ruby's), and timed one bench script per library before (`before*/`, copies of the phase-1
libraries) and after, 3 runs each, whole-process CPU time of `bin/sake --strict` (startup + check ≈ 0.7–1.0 s
included). Machine: the local development host, shared, load average 33–38 on 16 CPUs during all runs, so
these are informal (not sp4); interleaved before/after runs. Raw numbers: `results*.txt`, runners `run*.sh`.

| library | API change | CPU s before → after |
|---|---|---|
| base64 | `urlsafe_encode64(s, o = {padding: true})`; each function one pack/unpack1 | 4.3–4.7 → 0.71–0.73 |
| shellwords | Ruby's `\G` pattern at a position | 2.74–2.86 → 2.29–2.35 |
| cgi | `unescape(s, encoding = "UTF-8")`; escapers are one gsub; table by `once` | 3.97–4.19 → 1.76–1.85 |
| uri | `URI.join(base, r1..r3)`; optional `enc`; regexps/tables by `once` | 2.58–2.64 → 1.51–1.64 |
| erb | scans by position | 5.06–5.31 → 3.20–3.25 |
| json | `parse`/`generate`/`pretty_generate(x, o = nil)`, `_with` removed | 4.76–5.05 → 4.62–4.70 |
| csv | `_with` removed, options as optional last Record; one `\G` match per field | 5.4–5.9 → 2.4–2.6 |
| strscan | `\G` patterns cached with `once`, matched at the pointer | 11.8 → 11.4–11.7 (1 MB head-fail case 5.5 → 2.45) |
| abbrev | `abbrev(words, pattern = nil)` | 0.8 → 0.8 |
| tsort | `each_strongly_connected_component_from(g, node, id_map = .., stack = ..)`; components collected | 24 → 2.4 |
| digest | `hexdigest(x, s = nil)` etc.; unpack per block; constants by `once` | 10–13% faster |
| zlib | `crc32(s = nil, crc = 0)`, `adler32(s = nil, adler = 1)`; table by `once` | unchanged |
| prime | `each(ubound = nil)`; sieve kept by `once` | 61.4 → 16.5 |
| matrix | Ruby's defaults for zero/build/empty/round/rows, `which` argument | unchanged |
| date | defaults for civil/ordinal/commercial, `next_day(n = 1)`…, strftime/strptime/parse | 4.81–4.98 → 4.68–4.87 |
| optparse | `on` sorts args by content; parse/order/permute default to ARGV; --help/--version | 3.11–3.22 → 3.33–3.35 |
| logger | `info(msg = nil)`…, `add(sev, msg = nil, progname = nil)` | no difference |
| benchmark | `measure(label = "")`, Tms#format via gsub | 3.02–3.22 → 1.14–1.24 |

Conclusions: optional parameters removed every `_with` / `_label` variant name; Ruby's API shape is now
"same" for most entries (per-library tables in `sakelib/notes/*.md`, section "Phase 2"). Speed gains come
from replacing per-character interpreted loops with one built-in call (pack, gsub, `\G` match); where the
cost is per interpreted step (json tokens, strscan calls ≈ 0.3 ms each), avoiding string copies does not help.

Not changed (decisions): built-in failure messages keep the `Mod.op:` prefix (`String.unpack1: invalid base64`);
`Float.round(x, n)` stays Float for every n (the result type is the operation's, not the argument value's).

Remaining gaps: rest parameters (`URI.join`, `bm(*labels)`), keyword arguments (`Logger.new(level:)`;
misspelled option Record keys are ignored silently), `String#encode`, stderr `print`, `Math.acos`,
prime generators; tsort yields components after each traversal instead of as found (same order).
