# Notes (pilot, 10-grids)

## game_of_life
- Nothing notable. `include Indexable` with a Tuple index (`b[[x, y]]`, `nb[[x, y]] = v`) worked first try.

## maze_solver
- Tuple equality is not defined: `break if cur == goal` (both `[r, c]` Tuples) fails at run time with
  `TypeError: Kernel.==: no implementation for (Tuple, Tuple); ...`. Workaround: a top-level
  `same_pos?(a, b)` that destructures and compares components. Ruby keeps `cur == goal`.
  Tuples as Hash keys / Set elements work fine (by value), so only `==` is missing.
- `Array.each_cons(path, 3) do |a, b, c|` fails: `ArgumentError: block takes 3 parameter(s) but was
  given 1` — each window is an Array, and only Tuples are destructured into block params. Workaround:
  `|win|` and `win[0]`, `win[1]`, `win[2]`. Ruby keeps `|a, b, c|`. (Documented behavior, but a
  Ruby habit that only fails at run time with --strict=0.)
- Ruby uses `row.each_with_index`/`(0...@cols).map`; no enumerator chains in Sake, so the row is
  rebuilt with `Range.map(0...@cols)` in both.

## sudoku
- `Array.each_slice(@cells, 9).to_a` (enumerator without a block) is not expressible; collect rows
  with `Array.each_slice(@cells, 9) { |row| Array.push(rows, row) }`. Ruby keeps `each_slice(9).each_with_index`.
- Performance: the famous "hardest" puzzle (Inkala; 1850 guesses, 1.9 s in Ruby) did not finish within ~2 min
  in Sake (host load average ~30 at the time), so the corpus uses a medium puzzle (6 guesses). Whole program ~3 s user.

## tic_tac_toe
- Array patterns are unsupported: `case Board.outcome(b) in [:win, mark] ...` is a static error
  (`unsupported pattern `[:win, mark]`; use a type ...`). Workaround: `state, mark = Board.outcome(b)`
  then `case state in :win ...`. Ruby version uses the same shape.
- `break` inside a block is unsupported (`` `break` is only supported directly inside `while`/`until` ``).
  The script replay loop (`script.each { ...; break if winner }`) became an index `while` loop in Sake;
  Ruby keeps `each` + `break`.
- No unary minus: negamax writes `0 - Move.get_score(reply)`; Ruby writes `-reply.score`.
- Full-game negamax from move 2 took ~16 s user in Sake, so the first game starts after 3 moves.
- Exception with an extra field: `Exception.new(:square)` vs Ruby `class IllegalMove < StandardError`
  with `attr_reader :square` and `super(message)`.
