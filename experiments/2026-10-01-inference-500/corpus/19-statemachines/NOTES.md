# Notes: 19-statemachines

## turnstile
- Array patterns (`case [@state, event] in [:locked, :coin]`) are rejected: "unsupported pattern `[:locked, :coin]`; use a type (`in Integer`), a literal, `A | B`, or `{x:}`". Record patterns with literal values are rejected too ("only Record patterns that bind fields are supported"). Workaround: `case @state` with an `if event == ...` inside each branch.
- `sort_by` with a Tuple key (`[0 - n, a]`) fails at run time with a misleading message: "ArgumentError: Hash.sort_by: cannot compare elements of types Integer" (same for `Array.sort_by(...) { [String.size(a), a] }` -> "... of types String"). Repro: `p(Array.sort_by(Array["x", "yy", "z"]) { |a| [String.size(a), a] })`. Workaround: a String key, `format("%04d %s", 1000 - n, a)`.

## tcp_states
- Nested block-parameter destructuring (`Hash.each(h) { |(from, ev), (to, reply)| ... }`, natural in Ruby) is rejected: "nested destructuring `(a, b)` is not supported; `|a, b|` already destructures a Tuple". Workaround: `|key, value|` then `from, _ev = key` inside the block.
- Value constants are not allowed, so the transition table is a function `def transitions = Hash[...]` (rebuilt on each call) instead of `TRANSITIONS = {...}`.

## expr_lexer
- Two-argument indexing `s[i, 2]` is rejected ("`s[1, 2]` takes one index"); used Range indexing `src[i..i + 1]` / `src[start...i]` in both versions. (I first wrote `String[src, i, 2]`, which is the typed-Array constructor, not a substring.)
- `%w[and or not]` is not supported; `Array["and", "or", "not"]`.

## regex_nfa
- `Array + Array` is not in the operator table: "TypeError: Arithmetic.+: no implementation for (Array, Array)". Used `Array.concat(h1, h2)` and `Array.push(h, [s, 2])` (in-place; the left arrays are not reused) where Ruby writes `e1.holes + e2.holes`.

## elevator
- `min_by` with a Tuple key fails like `sort_by` in turnstile ("Array.min_by: cannot compare elements of types Integer"). Sake uses a numeric key `Integer.abs(f - @floor) * 100 + f` where Ruby uses `[(f - @floor).abs, f]`.

## csv_parser
- `Array[header] + good` is not available (no Array `+`); built with `Array[header]` then `Array.concat`. `[a, b].max` became an `if`, since `[...]` is a Tuple.

## event_sourcing
- Ruby reads `ev.seq` on any event class (duck typing). In Sake the five event Structs each include a mixin `module Event; def seq(ev) = get_seq(ev); end`, and `Event.seq(ev)` dispatches on the event's type. (A first version used a `case ev in Opened then Opened.get_seq(ev) ...` helper; both work.)
- Ruby's `state.transform_values(&:dup)` became an explicit `Account.copy` (no `dup` for Struct values).

## http_parser
- Multiple assignment from an Array (`m, path, version = String.split(line, " ")`) fails at run time: "TypeError: multiple assignment needs a Tuple, got Array". Used `Array.fetch(parts, 0), ...` on the right side. `String.partition` returns a Tuple, so `name, sep, value = String.partition(line, ":")` works.

## machine_mixin
- Worked as written. The mixin's `StateMachine.fire(machine, event)` dispatches over a heterogeneous script of `[Door|Light|Ticket, Symbol]` Tuples; the transition tables are functions that rebuild a Hash on each call (no value constants).

## bank_queue_sim
- Swapping through indexes, `@items[parent], @items[i] = @items[i], @items[parent]`, is rejected: "only `a, b = tuple` (local variables, no splat) is supported". Used a `tmp` variable in Sake. `loop do ... break` became `while true ... break` (no `break` in blocks). Runtime ~1.5-3 s on a loaded machine (load average ~34 at the time), so n was reduced from 40 to 30 customers.

## enemy_ai
- Ruby's `[@hp + 15, 100].min` became `Array.min(Array[@hp + 15, 100])` (`[...]` is a Tuple, and there is no `Integer.min`). Ruby needs an explicit `Vec#==` for `@pos == target`; Sake's Struct equality compares fields already.

## circuit_breaker
- **Interpreter bug (looks like):** a user function named `call` cannot be called with its type. `Service.call(svc, now, req)` is rejected before running with "type scope `Service.(...)` is not supported yet" — the explicit `.call` is treated like Ruby's `.()` shorthand. Minimal repro:
  ```ruby
  S = Struct.new(:a)
  class S
    def call(s) = @a
  end
  p(S.call(S.new(1)))   # error: type scope `S.(...)` is not supported yet
  ```
  Workaround: renamed the operation to `request` in both versions.
- `retry` inside `rescue` works as in Ruby.

## divisibility_dfa
- `Integer.to_s(n, base)` is not available ("wrong number of arguments for Integer.to_s (given 2, expected 1)"); wrote `to_base(n, base)` with a digit table in Sake, while Ruby uses `n.to_s(base)`.
- Nested Tuples as Hash keys (`delta[[[sa, sb], c]]`) and Tuples in Sets work.

## job_pipeline
- `path + [name]` (Array + Tuple) is not available; used `Array.push(Array.dup(path), name)`. `loop do ... break if ... end` became `while true` (no `break` in blocks).
