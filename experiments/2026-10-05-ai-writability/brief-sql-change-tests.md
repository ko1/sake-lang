# Brief: specify and test change CHANGE of a small SQL engine (AI writability, P11)

Twelve SQL engines exist, written by other AI agents in several languages from a specification in six
stages. Other agents will next be asked to change those engines. You write that change request: its
specification and its tests, checked against SQLite.

## Material

In `/home/ko1/app/sake/experiments/2026-10-05-ai-writability/`:
- `large/sql/spec/1-core.md` ... `6-windows.md`: the specification the engines implement. Read it all.
- `large/sql/changes/CHANGE/outline.md`: what the change is about. It lists candidate sites (the places in
  the language where the change shows); verify each with SQLite, keep the ones whose behaviour is clear
  and can be stated in a sentence or two, drop the rest.
- `harness/sql_oracle.py` computes a test's expected output with SQLite, adapted to the specification
  (read its docstring): `python3 harness/sql_oracle.py --write FILE.sql...` writes `FILE.out`, or prints
  `REJECT <file>: <reason>`; `python3 harness/sql_oracle.py FILE.sql` prints one file's output.
- `large/sql/tests/N/` (public tests of stage N): for the style of tests.

## Your job

1. Write `large/sql/changes/CHANGE/change.md`: the change, in the style of the spec files (start with
   `# Change: <title>`). It must be complete and exact enough to implement from the text alone, like
   the stage files: syntax, rules, examples, and every new or changed error message. It ends with a
   section `## Where it applies`: one line per kept site, `- <site-id>: <one sentence>`, where site-id
   is a short lowercase name (`order-by`, `unique`). Mark the sites the public tests exercise with
   `(public)`. For a change whose outline says *wide*, mark at most a third of the sites, the most
   central ones; for *local*, about half. Every rule in the text belongs to some listed site.
2. If the change adds error messages, write their patterns (Python regular expressions matching the
   whole message, one per line) in `large/sql/changes/CHANGE/catalogue.txt`; the oracle reads it.
3. Public tests, `large/sql/changes/CHANGE/tests/7/NNN-<topic>.sql`, about 8 files: only the sites
   marked `(public)`.
4. Hidden tests, `tasks/sql-change-hidden/CHANGE/7/NNN-<site-id>-<topic>.sql`: two or three files
   for **every** site, each file testing exactly one site (the one in its name) in a few statements,
   plus two or three files named `NNN-mixed-<topic>.sql` that combine the change with earlier stages
   in a small application. Hidden tests use different statements and data from the public ones.
5. Run the oracle with `--write` on both directories until it rejects nothing.

Rules for every test (as for the stage tests): use only what spec files 1-6 and change.md define, as
they write it (statements end with `;`; ASCII text; integers far from 64-bit limits); make the output
fully determined (a complete `ORDER BY` on any query with more than one row; at most one error per
statement); under 60 lines; prints at least one line. Check each output against change.md yourself.
When SQLite disagrees with what you wrote in change.md, fix change.md (it is yours); when SQLite
disagrees with spec files 1-6, record it in `large/sql/spec-issues/CHANGE.md` and do not keep a test
depending on it. Record there also any rule you dropped as unclear.

## Rules

Work only in `large/sql/changes/CHANGE/`, `tasks/sql-change-hidden/CHANGE/` and
`large/sql/spec-issues/CHANGE.md`. Do not read `runs/`, other
`tasks/` directories or other changes. No git. Shell commands need `dangerouslyDisableSandbox: true`.
Do not wait for processes by matching their names. Reply in under 150 words: the sites kept and
dropped, the counts of public and hidden tests, the oracle rejections you fixed, and any spec issues.
