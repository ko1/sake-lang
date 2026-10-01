# Sake language brief (v0 interpreter)

Sake uses Ruby syntax, but **operations are written with their type**: `String.upcase(s)`, not `s.upcase`.
Run a program with `bin/sake FILE.sake` (in `/home/ko1/app/sake`). All name errors are reported before execution.

## Rules

- `Type.op(x, args...)` calls an operation; the subject is the first argument. Method calls on values
  (`x.foo`, `"abc".upcase`, `3.times`) are errors.
- Operators `+ - * / % ** == != < <= > >=` work on Integer/Float (mixed allowed), String (`+`, comparisons,
  `String * Integer`). `==`/`!=` only between the same type (and Integer/Float). `7 / 2 == 3` (Ruby semantics).
- Functions: `def name(a, b) ... end` or `def name(a) = expr` at top level. Unqualified calls resolve to the
  current class/module first, then top-level functions, then Kernel (`puts`, `print`, `p`).
- Data types:
  ```ruby
  Point = Data.define(:x, :y)     # creates Point.new, Point.get_x, Point.set_x, Point.get_y, Point.set_y
  pt = Point.new(1, 2)            # positional arguments only
  Point.set_x(pt, 3)              # fields are mutable
  class Point                     # add functions to the Point namespace
    def norm2(p) = get_x(p) * get_x(p) + get_y(p) * get_y(p)   # inside, get_x means Point.get_x
  end
  def Point.dist(a, b) = ...      # same as defining inside `class Point`
  Point.norm2(pt)
  ```
  There is no `self`, no instance variables, no inheritance, no `attr_accessor`.
- `[a, b]` is a **Tuple** (fixed size). Destructure with `x, y = t`. Multiple return: `return a, b` or `[a, b]`.
- `Array[1, 2, 3]` is an **Array** (no declared element type). `Float[]`, `Integer[1, 2]`, `Point[p1, p2]`
  create an Array whose element type is declared and checked on every write.
- Blocks: `Array.each(xs) { |x| ... }`, `Integer.times(3) { p it }`, `_1`/`_2` work.
  User functions take a block only through `yield`. `next`, `break` (in while), `return` work as in Ruby.
- `if`/`elsif`/`else`/`unless`, `while`/`until`, `&&`, `||`, `x += 1`. Only `nil` and `false` are falsy.

## Not available (static error)

Indexing `a[i]` / `t[0]`, unary operators (`!x`, `-x`; write `x == false`, `0 - x`), string interpolation
(use `String.+` and `Integer.to_s`), symbols, Hash, `case`, `&blk`/`proc`/`lambda`, `%w[]`, ranges,
`Array.new`, and operations that return nil on a miss (`first`, `last`, `find`, `min`, `max`, `pop`, `index`).

## Built-in operations (Ruby names)

- Kernel: puts(*any), print(*any), p(x)
- Integer: + - * / % ** < <= > >= == != (both Integer), to_s, to_f, abs, succ, pred, even?, odd?, zero?,
  times(n) { |i| }, upto(a, b) { |i| }, downto(a, b) { |i| }
- Float: + - * / % ** < <= > >= == != (both Float), to_s, to_i, floor, ceil, round(f, [digits]), abs, nan?
- String: + == != < <= > >=, *(s, n), length, size, upcase, downcase, capitalize, swapcase, reverse, strip,
  lstrip, rstrip, chomp, empty?, to_i, to_f, chars, lines, to_s, include?(s, t), start_with?(s, t),
  end_with?(s, t), split(s, [sep]), sub(s, a, b), gsub(s, a, b), count(s, t), each_char(s) { |c| },
  ljust(s, n, [pad]), rjust(s, n, [pad])
- Array: Array[...], length, size, empty?, push(a, *xs), append(a, *xs), concat(a, b), include?(a, x),
  join(a, [sep]), reverse, sum, sort, sort_by(a) { |x| }, take(a, n), drop(a, n), each(a) { |x| },
  each_with_index(a) { |x, i| }, map, select, filter, reject, any?, all?, none?, count (all with a block),
  reduce(a, init) { |acc, x| }, inject(a, init) { |acc, x| }
- Tuple: length, size
- Math: sqrt, cbrt, sin, cos, tan, atan, exp, log, log2, log10, atan2(y, x), hypot(x, y)

## Example

```ruby
Item = Data.define(:name, :price)

def total(items) = Array.reduce(items, 0) { |acc, it| acc + Item.get_price(it) }

items = Item[Item.new("apple", 120), Item.new("pear", 200)]
puts(total(items))
Array.each(items) { |it| puts(String.+(Item.get_name(it), String.+(": ", Integer.to_s(Item.get_price(it))))) }
```
