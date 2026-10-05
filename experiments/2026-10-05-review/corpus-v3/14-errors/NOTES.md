# Notes (14-errors, corpus-v2)

Workarounds still needed with today's Sake:

- String Ranges still cannot be iterated (spreadsheet_errors keeps the `String.ord`/`Integer.chr` workaround):
  `p(Range.to_a("A".."C"))` gives `TypeError: Range.to_a: this operation needs a Range that starts with an Integer, got "A".."C"`.
- `Array.last` still has no count (password_policy keeps `Array.take(Array.reverse(h), 3)`):
  `Array.last(Array[1, 2, 3], 2)` gives `wrong number of arguments for Array.last (given 2, expected 1)`.
- Still no guards in `in` branches (expr_calculator keeps the test in `else`):
  `case x in Integer if x > 0 ...` gives `unsupported pattern`.
- Still no nested Record patterns (result_pipeline keeps `in {ok:}` and then `ok => {...}`), and still no way
  to extend a Record, so each step rebuilds the whole Record.
- `e in T ? a : b` still needs parentheses (also true in Ruby); unit_quantities and spreadsheet_errors keep them.
- No automatic `Exception#cause` (error_wrapping keeps an explicit `cause` field walked with `case`/`in`).
- `puts(e)` of an exception still prints `#<E: m a=1>`, where Ruby prints the message.
- Index access was kept where an Array has more elements than the code reads: there are no splats in
  multiple assignment or block parameters. Examples are csv_import (`cells[0]`..`cells[3]` of 6 cells) and
  param_coercion (`s[0] == k` on a 4-element spec Tuple).

Resolved since corpus/:

- A user function named `call` now works (`Service.call(svc, x)` runs). retry_backoff keeps the name
  `request`, because the Ruby version uses it too.
- Tuple ordering, Tuple equality, unary minus and `!x` replaced every workaround of that kind (see CHANGES.md).

No interpreter bugs found.
