## A. Parameter requirements from each function's body alone

500 programs (0 failed to analyze); 6919 parameters, 6769 of them reached when the program runs.

| requirement | all parameters | reached at run time |
|---|---|---|
| one | 3857 (55.7%) | 3828 (56.6%) |
| union | 1297 (18.7%) | 1294 (19.1%) |
| any | 1764 (25.5%) | 1646 (24.3%) |
| none | 1 (0.0%) | 1 (0.0%) |

Union sizes: 2: 184, 3: 460, 4: 250, 5: 339, 6: 64

Most common unions:
- `Float|Integer|Rational` 373
- `Complex|Float|Integer|Rational` 191
- `Array|Hash|MatchData|String|Tuple` 168
- `Complex|Float|Integer|Rational|Time` 152
- `Array|Hash|Tuple` 50
- `Float|Integer|Rational|String` 44
- `Array|Tuple` 43
- `Array|Complex|Float|Integer|Rational|String` 41

Reached parameters whose requirement equals the set of types they get at run time: 3939 of 6769 (58.2%).
Instrument check: run-time types outside the derived requirement: 7 parameters.
- 01-text/json_pretty.sake pretty#0: requirement Array|Hash, got String|Boolean|Float|Nil|Integer
- 06-linked/list_toolkit.sake L.kth_from_end#0: requirement Cons, got Nil
- 06-linked/list_toolkit.sake L.palindrome?#0: requirement Cons, got Nil
- 06-linked/list_toolkit.sake L.rotate_right#0: requirement Cons, got Nil
- 07-trees/rope_editor.sake char_at#0: requirement RLeaf, got RNode
- 14-errors/order_lifecycle.sake Order.fire#2: requirement , got Integer|String
- 15-data/table_renderer.sake render_cell#1: requirement Nil, got String|Integer|Float

Errors found only by the local analysis (code the whole-program typer never reaches): 0

## B. Without the fixpoint over fields and elements (unknown unless declared)

| | whole program | fields and elements unknown |
|---|---|---|
| checks decided (proven / may fail / fails) | 54530 of 54611 (99.9%) | 28545 of 41489 (68.8%) |
| proven | 50562 | 27716 |
| unknown | 81 | 12944 |
| correct programs rejected at level 1 | 52 | 51 |
| correct programs rejected at level 2 | 299 | 115 |
