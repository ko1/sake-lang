# Sake's test suite, in Sake

Each `*_test.sake` here is a program written with `sakelib/minitest.sake`: it builds a suite, registers tests
as blocks, and ends with `Minitest.run(suite)`, which exits with 1 when a test failed. `test/test_sake_suite.rb`
runs every file with `bin/sake --strict` and checks the exit status and the summary line, so `rake test`
covers them too.

The expected values are written in the tests (they are what Ruby gives for the same operation; when in doubt,
run the Ruby expression). `core_test.sake` covers the built-in operations added on 2026-10-09
(`experiments/2026-10-09-stdlib-port/`).
