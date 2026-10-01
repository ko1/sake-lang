# Where TypeProf's `untyped` comes from

TypeProf 0.31.1, Ruby 4.0.2. The 451 corpus programs that TypeProf finished (`../../results-head/typeprof.jsonl.gz`).
Numbers from `analyze.rb` (report in `report.md`); probes are the `.rb` files in this directory.

## Untyped is not about methods that never run

Each corpus program was run with `called_trace.rb` (TracePoint `:call`) to record which of its methods ran.

| unit | slots | with untyped (whole or inside) | in methods that never ran | in methods that ran |
|---|---|---|---|---|
| parameter | 4,516 | 428 (9.5%) | 22 | 406 |
| return | 3,550 | 301 (8.5%) | 5 | 296 |
| attr reader | 2,299 | 184 (8.0%) | 0 | 184 |

So almost all untyped slots are in code that does run with concrete values. Shapes, in methods that ran:
plain `untyped` 514, `Array[untyped]` 114, `Hash[K, untyped]` / `Hash[untyped, V]` 83, `Array[... untyped ...]` 66,
a tuple with an untyped element 48, other unions containing untyped 76.

## Causes confirmed with minimal programs

### 1. `module_function` methods are analyzed as instance methods only (`mf.rb`)

```ruby
module M
  module_function
  def twice(x) = x * 2
end
module N
  def self.twice(x) = x * 2
end
p M.twice(3)
p N.twice(3)
```

```
module M
  def twice: (untyped) -> untyped
end
module N
  def self.twice: (Integer) -> Integer
end
```

The calls `M.twice(3)` reach the singleton copy that `module_function` makes, which TypeProf does not
connect to the definition. In the corpus: 85 of the 913 untyped slots, in 11 programs, are in modules
that use `module_function`.

### 2. Multiple assignment from an `Array[T]` gives the first variable the whole Array (`masgn.rb`, `masgn2.rb`)

```ruby
def from_call(s)
  a, b = s.split(",")
  a
end
def from_local(s)
  parts = s.split(",")
  a, b = parts
  a
end
def from_map(xs)
  a, b = xs.map { |x| x * 2 }
  a
end
p from_call("x,y"), from_local("x,y"), from_map([1, 2])   # "x", "x", 2
```

```
def from_call: (String) -> Array[String]
def from_local: (String) -> Array[String]
def from_map: ([Integer, Integer]) -> Array[Integer]
```

The inferred type is wrong, not just imprecise: at run time `a` is a `String` / an `Integer`. With a
tuple-typed right side (`a, b = pair` where `pair` returns `[1, "a"]`, or `String#partition`) the
types are right. The corpus has 612 lines of multiple assignment from a non-literal right side, in 305
programs (`grep` on the Ruby sources; some of these have tuple types and are fine). Untyped values
downstream often start here; for example `a, b, km = line.split` followed by `Edge.new(idx[a], idx[b], km.to_i)`
(`corpus/07-trees/spanning_tree.rb`), where `Edge#a` is reported `untyped`. That this chain is the cause
in that program is an inference from reading it, not verified by changing the program.

### 3. `map(&:sym)` gives untyped elements (`probes.rb`)

```ruby
def symproc(xs) = xs.map(&:to_i)
p symproc(["1"])
```

```
def symproc: ([String]) -> Array[untyped]
```

## Not yet explained

Most untyped slots were not traced to a cause. The sample at the end of `report.md` lists one in 25 of
them with its program, for anyone who wants to continue.
