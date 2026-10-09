# minitest

Ruby's Minitest, in Sake, for tests written in Sake (`test/sake/*_test.sake`).

## What differs from Ruby and why

- **Tests are blocks, not methods.** Ruby's Minitest finds `test_*` methods by reflection; Sake has none, so
  `Minitest.test(suite, "name") { |t| ... }` registers and runs a test, and the block receives the test case `t`
  that every assertion names first (`Minitest.assert_equal(t, expected, actual)`), as every Sake operation names
  its subject. There is no `setup`/`teardown`: write the setup at the top of the block, or in a function.
- **No autorun.** `Minitest.run(suite)` at the end of the file prints the report and exits with 1 on failure.
- **`assert_raises` gives the message, not the exception.** A test cannot name an exception type as a value,
  so it checks the message (`assert_match`).
- **`assert_equal` is Sake's `==`**: a Tuple literal `[1, 2]` does not equal an Array `Array[1, 2]`; compare an
  Array result with `Array[...]`.
- **No `assert_output`, `capture_io`, `skip`, `assert_predicate`, `assert_kind_of`** (no output capture, no
  types as values). `assert_includes` takes an Array, String, Hash, Set, or Range.

## Built-ins used

`Time.now`, `Arithmetic.abs`, the union call `(Array|String|Hash|Set|Range).include?`, `Kernel.exit`.
