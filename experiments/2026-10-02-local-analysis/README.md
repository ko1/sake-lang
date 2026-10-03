# How much of Sake's checking needs whole-program analysis (2026-10-02)

Question (ko1): does Sake need global analysis, and if the boundaries must be typed, where are they?
Sake's operations carry their types, so the result of `String.upcase(...)` is known locally; the
holes are parameters, user function results, fields, and collection elements. Two measurements on the
500 programs of `../2026-10-01-inference-500/corpus-v2` (all correct: they run and match Ruby's output).

- Implementation: commit in `out/commit.txt` (the typer of 77d3ba1 + the IDE commit, unchanged by this experiment).
- `local.rb` (method in its header), `summarize.rb` → `out/summary.md`, `declared.rb` → `out/declared.txt`.
- Run: `ls ../2026-10-01-inference-500/corpus-v2/*/*.sake | xargs -P 8 -n 10 ruby local.rb > out/local.jsonl` (the run used one file per batch, then concatenated), then `ruby summarize.rb`.

## A. Parameter requirements from each function's body alone

Each function is analyzed by itself, every parameter an opaque value; the operations applied to it
(a built-in's parameter type, operator rows, indexing, a getter, a module's dispatch, a call to another
function with it) narrow what it may be; `x in T`, `case x in T` and nil checks exclude types on their
paths; a `case/in` without else limits it to the branches' types.

| requirement (reached parameters, 6,769) | |
|---|---|
| one type | 3,828 (56.6%) |
| a union | 1,294 (19.1%) — mostly the numeric tower (`Float\|Integer\|Rational` 388, with Complex 198, with Time 154) or indexables (`Array\|Hash\|MatchData\|String\|Tuple`) |
| no requirement | 1,646 (24.3%) — passed through: stored, printed, compared with `==`, returned |
| none works | 1 |

The requirement equals the set of types the parameter really gets at run time for 58.2%.

**Instrument check.** A requirement must contain every type the parameter gets when the program runs.
Seven parameters violate it (0.1%), all through correlations a local analysis does not follow: a user
predicate (`return ... if scalar?(v)`), an alias tested instead (`lead = list; return unless lead`),
the exit of `while r in RNode` (which the typer does not narrow either), and a parameter used as
Integer under `case event in :pay` and as String under `in :ship` (the requirement intersects branches;
a union over exclusive branches would be right).

Corrections during the measurement (instrument bugs, found by the check above, fixed before the
numbers here): an operator with an empty (unreached) operand constrained to nothing (21 violations →
10); a parameter's elements were empty instead of unknown (nonogram); a parameter written into a shared
Hash and read back in another function constrained the first one (lisp_interp; 11 → 7).

No error was found only by the local analysis in functions the whole-program typer never reaches (the
corpus has 78 such functions; they contain no surely failing operation).

## B. Without the fixpoint over fields and elements

The whole-program typer, with every field read and every Array/Hash/Set element unknown unless declared:

| | whole program | fields and elements unknown |
|---|---|---|
| checks decided | 54,530 of 54,611 (99.9%) | 28,545 of 41,489 (68.8%) |
| proven | 50,562 | 27,716 |
| correct programs rejected, level 1 / 2 | 52 / 299 | 51 / 115 |

Fewer rejections here mean less checking: unknown is never reported. Declarations that would stop the
fixpoint are rare: 11 of 2,850 fields have a declared type, 562 of 6,908 Array sites are `T[...]`, and
Hash (1,018 sites) and Set (335) have no way to declare elements.

## C. Struct fields per definition (ko1: "Struct has attributes, so fields may not need much")

A Struct names its fields, and every write is a typed operation (`T.new`, `T.set_x`, `@x = v` in its
class), so a field's write sites are known syntactically. Its type is the union of the values written
there, which needs the fixpoint only when a written value itself comes from a field or an element.
`field_writes.rb` (writes whose value type is still known with fields and elements unknown):

- write sites: 5,611 of 6,782 (82.7%) write a value known without fields and elements;
- fields: 1,619 of 2,296 written fields (70.5%) have only such writes (2,850 fields in all; the rest are
  written nowhere the typer reaches).

Proven checks, separating the two parts (`split.rb`, `struct_fields.rb`; whole program: 50,562):

| | proven checks | vs whole program |
|---|---|---|
| fields unknown | 38,786 | −23% |
| elements unknown | 32,827 | −35% |
| both unknown | 27,716 | −45% |
| elements unknown, fields inferred per definition when all writes are local | 31,270 | −38% |

Inferring fields per definition recovers 3,554 of the 5,111 proven checks that fields add when elements
are unknown (70%). Fields are mostly fine without declarations; collection elements are the larger,
harder part: an Array is anonymous, and where it is filled (push, `[]=`) follows wherever it flows.

Correction during C: the first count of fields (4,850) included four built-in exception types missing
from `Resolver::BUILTIN_EXCEPTIONS` (TypeError, NoMatchingPatternError, SystemStackError,
NotImplementedError); built-in types are now those of an empty program.

## Conclusion

- Parameters do not need written types: three quarters get a requirement from the body alone (most a
  single type), and the rest are genuinely polymorphic. With per-argument-type evaluation of calls
  (cached by the callee), function signatures are modular without annotations.
- The global part is data: about 45% of the proven checks depend on field and element types collected
  over the whole program.
- Struct fields mostly do not need declarations (C): 70% of written fields get their type from their
  write sites alone. Collection elements are the part that needs the whole program (−35% alone); if
  anything is to be written, it is element types (`T[...]` exists for Arrays; Hash and Set have none).
- Not measured yet: how many Arrays are created and filled within one function (local) versus filled
  after being passed or stored.
