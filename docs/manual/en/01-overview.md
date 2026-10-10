# Overview and running programs

Sake (/seɪk/) is an experimental language designed for the sake of finding a new place for types. It keeps Ruby's syntax, but you write the type on each **operation**, never on a variable, a parameter, a return value, or a field.

```ruby
String.upcase(name)        # Sake
name.upcase                # Ruby's spelling: a static error in Sake, whose hint gives the line above
```

This book is the reference manual of the language as implemented by the v0 interpreter (`bin/sake`). For a guided introduction see [tutorial.md](https://github.com/ko1/sake-lang/blob/main/docs/tutorial.md); for a short summary to hand to a language model, [cheatsheet.md](https://github.com/ko1/sake-lang/blob/main/docs/cheatsheet.md) (about 10k tokens); the design notes and their reasons are in `DESIGN.md` (in Japanese).

## Principles

1. **Ruby syntax.** A Sake program is a Ruby program as parsed by Prism. Sake accepts a subset of Ruby's syntax and gives some constructs a different meaning.
2. **Types are written on operations, not on bindings.** An operation is called with its type, `Type.op(subject, args...)`. Variables, parameters, return values, and fields carry no type annotations.
3. **Every call target is known before running.** There is no dispatch on the receiver, no `method_missing`, and no reflection. Name errors are reported for the whole program before execution starts.
4. **Values carry type tags, and every operation checks them.** A wrong type is reported as an error at the operation that received it, with the line number. These checks are always enabled.

## Running

```
bin/sake FILE.sake              # check, then run
bin/sake -c FILE.sake           # check only
bin/sake --strict FILE.sake     # check more strictly (level 2), then run
bin/sake --strict=3 FILE.sake   # levels 0-4, or items: --strict=type,nil
bin/sake --types FILE.sake      # experimental: print the inferred types instead of running
bin/sake --dump=ast FILE.sake   # print the resolved program (SakeAST)
```

| Exit status | Meaning |
|---|---|
| 0 | success |
| 1 | runtime error |
| 2 | problem found before running (nothing was executed) |

The interpreter is written in Ruby and needs Ruby 4.0 (tested with 4.0.2 and Prism 1.9.0). It has no other dependencies.

## Strictness (`--strict`)

`--strict` sets which problems stop the program before it runs. Each item is reported from the whole-program type inference; whatever is not reported is still checked while running.

| Level | Option | Items | Stops before running |
|---|---|---|---|
| 0 | `--strict=0` | (none) | syntax, names, argument counts, blocks, calls on values, forbidden syntax, literal types in `T[...]` (always checked) |
| 1 | default | `type`, `rescue` | a value whose type, other than nil, does not fit (`"" + 1`, or `pick() + 1` where `pick` returns 1 or ""); a `rescue` of an exception the begin body never raises |
| 2 | `--strict` | `type`, `rescue`, `nil`, `mixed` | also a value that may be nil, used without a check (except the nil of a miss: `x[k]`, `Array.dig`, `Hash.dig`, `MatchData.begin`/`end`, and `Array.first`, `last`, `pop`, `shift`, `min`, `max`, `minmax`, `at`, `slice`, `sample`, `delete_at`, `Set.first`, `min`, `max`, `min_by`, `max_by` on an empty collection); and a `mixed` report (below) |
| 3 | `--strict=3` | `type`, `rescue`, `nil`, `mixed`, `index-nil`, `exhaustive` | also the nil of a miss (`x[k]`, `Array.first` and the others above), used without a check; a `case`/`in` that may get a value of an open type (String, Integer, a Symbol not written as a literal, ...) that no literal branch takes |
| 4 | `--strict=4` | all of the above, `unrescued` | also a `raise` that may reach the top level without being rescued (for a program; a library's raises are meant for its callers) |

- **`mixed`.** A type report whose failing types all appear, together with fitting ones, in one field (or in the elements of a container held in a field) of a class. The checker gives a field one type per construction site ([Classes](07-classes.md)), so instances made at one place and used for different values (one function's Heap used for Integers and for Jobs) meet there; the report is likely such a meeting rather than a mistake. It stops the program from level 2; at level 1 it is printed as a warning. The cost of the heuristic: a field that really got a wrong type (`Config.new("h", "eighty")` for an Integer port) is also `mixed`; check such a value where it is stored, in `initialize` (`@port => Integer`).
- **Naming items.** `--strict=type,nil` selects exactly these items. `--strict=2,index-nil` adds an item to a level, and `--strict=3,-index-nil` removes one.
- **Labels.** Each report ends with its item, such as `[type]`.
- **Errors inside functions.** A report inside a polymorphic function adds a hint naming the call that led there.
- **Unreached branches.** Branches are not evaluated, so a problem in a branch that never runs is still reported, as in Erlang's Dialyzer.
- **Internal errors.** If the type inference itself fails, the type checks are skipped with a warning, and the program runs.
- **Too many element pairs.** Comparing Arrays or Tuples (`<`, `<=>`, sorting) checks that each pair of element types can be compared. When the element types of one comparison make more than 50,000 pairs, that comparison's elements are not checked, with a warning at the comparison.

## Format of static errors

Static errors are reported all together, sorted by position, and nothing runs.

```
FILE:LINE:COLUMN: error: MESSAGE
  hint: SUGGESTION
```

## Format of runtime errors

```
FILE:LINE: in FUNCTION: KIND: MESSAGE
  from FILE:LINE: in CALLER
  hint: SUGGESTION
```

The kinds are listed in [Exceptions and errors](08-exceptions.md).
