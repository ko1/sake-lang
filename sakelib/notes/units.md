# units

`sakelib/units.sake`: quantities with units, after the ruby-units gem: length (m, km, cm, mm, in, ft, yd,
mi), mass (kg, g, mg, t, lb, oz), time (s, ms, min, h, day), the derived N, J, L, and units built from
them with `*`, `/` and `^n` (`km/h`, `m/s^2`, `kg*m/s^2`). Conversion, `+ - * /`, comparison, the kind
(:speed, :force, ...). The reference is `test/sakelib/ref/units.rb`. 24 functions; the test prints 58
lines, identical to `units.rb`.

## API

| Ruby (ruby-units) | Sake | |
|---|---|---|
| `Unit.new("5 km/h")`, `"5 km/h".to_unit` | `Unit.parse("5 km/h")` | differs: name |
| `Unit.new(5, "km/h")` | `Unit.new(5, "km/h")` | same |
| `u.convert_to("m/s")`, `u.to("m/s")` | `Unit.convert_to(u, "m/s")` | same (`to` missing) |
| `u.scalar`, `u.units`, `u.kind`, `u.compatible?(v)`, `u.to_base`, `u.base_scalar`, `u.round(n)` | same | same |
| `u + v`, `u - v`, `u * v`, `u / v`, `u * 3` | same | same (`+`/`-` convert v to u's units) |
| `u < v`, `==`, `sort`, `max` | same | same; incompatible units raise ArgumentError |
| `u.to_s` (`"90 km/h"`), `inspect` | same, `%g` | differs in the number format |
| temperatures, prefixes on any unit (`Mm`, `ns`), `u ** n`, Rational scalars, `Unit.define` | | missing |

## What differs from Ruby, and why

- `Unit.new` takes the scalar and the units, the type's two fields (a `new` takes fields), and
  `initialize` parses the units; a String with both is `Unit.parse`.
- Scalars are Floats, printed with `%g` (6 significant digits): ruby-units keeps Integers and Rationals.
- A unitless ratio keeps its units uncanceled across different units of one kind (`1 km / 200 m` is
  `0.005 km/m`, kind :unitless); ruby-units simplifies it to 5.
- Only the units in the table exist; there is no prefix grammar.

## Friction

1. `Unit.num(b)` for the other operand of `*` → `field num of Unit is private (private attr_*)`, with the
   hint "inside class Unit, use @num", which reads only the first parameter's field. Ruby would make the
   readers `protected`; Sake has no such level → plain `attr_reader num, den`.
2. The units table entry is `[factor, [l, m, t]]`, a Tuple: I wrote `Array.fetch(entry, 0)` →
   `Array.fetch: argument 1 must be Array, but is [Float, [Integer, Integer, Integer]]` → `entry[0]`.
   A good message, with the hint about Tuples.
3. Constant tables → `def table = once do ... end`, `def kinds = once { Hash[[0, 0, 0] => :unitless, ...] }`
   (Tuple keys work).
4. `@scalar => Integer | Float` in `initialize` would not narrow the field (see
   `lru_cache_bug_initialize_assert_field.sake`) → checked locals written back (`s = @scalar; s => ...;
   @scalar = Arithmetic.to_f(s)`).
5. A wrong-typed scalar in the test (`Unit.new("5", "m")`) would be a `[type]` report before running →
   `Array.fetch(Array[1, "5"], 1)` to reach the run-time `NoMatchingPatternError`.

## Language features used

- `initialize` as a converter (units String → canonical units, num/den lists; scalar → Float): helped,
  `Unit.new(90, "km/h")` reads like ruby-units.
- `include Arithmetic` + `def +`, `-`, `*`, `/` and `include Comparable` + `<=>`: `force = mass * g`,
  `Array.sort` of lengths: helped.
- `@num, @den = parse_units(text)`: multiple assignment to fields.
- `x => Integer | Float`; `b in Unit` in `*` and `/` to take a number or a unit.

## Checker findings before the test passed

- `--strict=1` and `--strict=2`: friction 1 and 2 (errors before running, not type-level items).

## Types

- `Unit.scalar: Float`, `Unit.units: String`, `Unit.num` / `Unit.den`: `String[]` from two sites.
- partial: the `=> Integer | Float` check (it gets a String in the error test). No unknowns.
