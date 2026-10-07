# Change m08: new written form for strings and nil

The way values are written as text changes in two ways. This replaces the
`repr` rows for strings and for `nil` in SPEC.md section 8.1; everything not
mentioned here stays as in SPEC.md.

## 1. `repr` of a string uses single quotes

A string is written between single quotes `'`. Inside, these characters are
escaped, and no others:

| Character | Written as |
|---|---|
| backslash | `\\` |
| single quote `'` | `\'` |
| `{` | `\{` |
| newline | `\n` |
| tab | `\t` |

A double quote `"` is no longer escaped: it is written as itself. `}` is
written as itself, as before. The empty string is `''`.

## 2. `nil` is written as `null`

`str(nil)` and `repr(nil)` are both `null`. Since every place that turns values
into text uses `str` or `repr`, this applies to `print`, `str`, `join`,
interpolation, elements and map values inside arrays and maps (at any depth up
to the `...` limit, which is unchanged), the `assert` message, and the value
shown by `uncaught throw`.

## 3. Error messages

Messages that show a value use `repr` and so follow the new form:

- `key 'b' not found` (map read, `m.name`, `del`); int keys stay bare (`key 7 not found`);
- `int: cannot convert 'x' to int`;
- `uncaught throw 'oops'`, `uncaught throw null`, `uncaught throw {'a': null}`.

Positions and kinds of all errors are unchanged.

## 4. What does not change

- Source syntax: string literals are still written with double quotes; `\'` in
  a literal is still `invalid escape '\''`, and `'` outside a string is still
  an unexpected character. The keyword is still `nil`; `null` is an ordinary
  name.
- Type names: `type(nil)` is still `"nil"`, and messages that name a type say
  `nil` (`cannot negate nil`, `cannot apply '+' to nil and int`,
  `len: argument 1 must be a string, array or map, got nil`).
- Messages that quote source text (lexical, syntax and static errors) are
  unchanged.
- `str` of a string is still the string itself; ints, bools, functions and
  built-ins are written as before.

## Examples

    print([nil, "it's", "say \"hi\""], nil)

prints

    [null, 'it\'s', 'say "hi"'] null

---

    let m = {"a": nil}
    print("m is {m}, type {type(m.a)}")
    print(m.b)

prints

    m is {'a': null}, type nil
    runtime error at 3:8: key 'b' not found

---

    throw {"why": ["x\ty", "\{"]}

prints

    runtime error at 1:1: uncaught throw {'why': ['x\ty', '\{']}
