# A SQL engine in Sake

`main.sake` and the 45 files under `sql/` (4,563 lines) are a SQL engine for a subset of SQLite:
tables and types, INSERT/UPDATE/DELETE, SELECT with joins, subqueries, GROUP BY and aggregates,
ORDER BY, compound queries, CTEs (also recursive), views, indexes, ALTER TABLE, transactions,
window functions, and BLOB values. It reads a SQL script on standard input, prints each SELECT's
rows with `|` between the columns, and prints `Error: <message>` for a statement that fails before
going on to the next one. The specification is [SPEC.md](SPEC.md); [CHANGE.md](CHANGE.md) is the
last change applied to it (BLOB values).

```
bin/sake examples/apps/sql/main.sake < examples/apps/sql/main.stdin
```

`main.stdin` is a short demonstration script and `main.expected` its output (this is what
`ruby test/test_examples.rb` checks). Checking the program before it runs takes a few seconds.

## Where it comes from

The engine was written by AI (Claude Sonnet 5.5) for the AI-writability evaluation,
[experiments/2026-10-05-ai-writability/](../../../experiments/2026-10-05-ai-writability/README.md):
in P10 one agent per stage grew it from scratch over six stages of the specification, each stage
adding features and passing the public tests of stages 1..N (this is the second of the two Sake
series, `p10-sake-2`); in P11f another agent applied the BLOB change (`c2-blob`) to it. The code here is
`runs/p11f-t-sake-2-c2/final/code/` of that experiment, unchanged. It passes all 374 public
tests (stages 1-6 and the change's stage 7) and, in the evaluation, 55 of 55 hidden tests of the
change.

## Running its tests

The tests are SQL scripts with their expected output, computed with SQLite and kept in the
experiment (3 MB, not copied here). The experiment's runner checks the program once with
`--strict=2 -c`, then runs each test at `--strict=0`, eight at a time:

```
SQL_TESTS=experiments/2026-10-05-ai-writability/runs/p11f-t-sake-2-c2/tests \
  ruby experiments/2026-10-05-ai-writability/large/sql/run_tests.rb examples/apps/sql/main.sake
```

`--stage N` runs the tests of stages 1..N only; a name substring selects single tests
(`ruby ... run_tests.rb examples/apps/sql/main.sake 6/ window`). On 2026-10-10: `374 passed, 0 failed`.
