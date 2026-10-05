# Notes: grids, boards and puzzles (corpus-v2)

All 25 programs exit 0 under `bin/sake --strict=0` and match their `.out` byte for byte.

## Still worked around

- `break` inside a block is still a static error: battleship, minesweeper, hex_game, and game_2048
  keep `next if finished` / `next if ...` to skip the remaining iterations.
- Swapping through index targets (`a[i], a[j] = a[j], a[i]`) is still rejected; sliding_puzzle and
  falling_sand keep a temporary.
- No `Array + Array`, `Array.new(n, v)`, or splats: nonogram builds rows with pushes and
  `Array.concat(Array.dup(head), tail)`; chess_attacks uses `Array.concat(Array.dup(straight), diagonal)`;
  battleship/othello use `Array.unshift(rows, header)`.
- No Record indexing (`d[:name]` raises `TypeError: {name: String} cannot be indexed`): word_search
  still takes each direction apart with `d => {name:, dr:, dc:}`, including inside `Array.find`.
- A user `[]` takes one index (`m[1, 2]` is rejected), so matrix_spiral keeps `m[[r, c]]`.
- No enumerator chains (`each_slice(3).map`, `each_with_index.map`): sudoku_solver and magic_square
  keep a block that pushes into `Array[]`.
- No nested block parameters `|(ar, ac), (br, bc)|`: maze_bfs takes the three cells apart inside
  the block (`|a, b, c|` then `ar, ac = a`), which is now short enough.
- No value constants: tables are still functions (`lines`, `dirs`, `jumps`, `turn_right`).

## Possible interpreter issue

- The hint for `Array.new` suggests a non-existent form:
  `p(Array.new(3))` -> `error: undefined function `Array.new`` / `hint: did you mean `Array.new[]`?`
  (presumably meant `Array[]`).

## Fixed since the first round

- `Array.join(a)` without a separator no longer crashes.
- The `sort_by` error now names the right type (`cannot compare block results of types Tuple ...`).
