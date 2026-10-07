# Change m03: bool and nil map keys

From now on a map key may be a string, an int, a bool (`true`, `false`) or
`nil`. Arrays, maps and functions remain invalid keys. Everything not
mentioned here stays as in `SPEC.md`.

## Keys

- Keys are compared with `==` (section 4), so values of different types are
  different keys: `true`, `1` and `"true"` are three distinct keys, as are
  `false`, `0`, `nil`, `"nil"` and `""`.
- Every place that accepts a key accepts the new ones in the same way:
  map literals (`{true: 1, nil: 2}`; a repeated key keeps its first place and
  its last value, as before), reading `m[k]`, assignment `m[k] = v` and
  compound assignment `m[k] += v`, `in` and `contains`, and the built-ins
  `has`, `get` and `del`.
- `keys(m)`, `values(m)` and `for k in m` / `for k, v in m` include the new
  keys in insertion order, unchanged in type (`type(k)` is `"bool"` or `"nil"`).
- Map equality is unchanged in definition: same set of keys (by `==`), each
  with equal values, in any order. So `{true: 1} == {1: 1}` is false.
- Field access is unchanged: `m.name` is always the string key `"name"`, and
  a keyword after `.` (`m.nil`, `m.true`) is still the syntax error
  `expected name, got 'nil'`.

## Text

`repr` (and therefore `str`, `print`, interpolation and `join`) writes a map
entry's key as `repr` of the key, so bool and nil keys appear bare:
`{true: 1, nil: "x"}`. A missing bool or nil key is the `key` error
`key true not found`, `key false not found` or `key nil not found`.

## Error messages

An invalid key (array, map or function) is now the runtime `type` error

    map key must be a string, int, bool or nil, got <type>

at the same positions as before (the key expression in a literal; the `[`
or `.` for indexing). For `has`, `get` and `del` the phrase for argument 2
is now `a string, int, bool or nil`:

    has: argument 2 must be a string, int, bool or nil, got array

`x in m` (and `contains(m, x)`) for a map `m` is `false`, not an error, when
`x` is an array, map or function.

## Examples

    let m = {true: "yes", 1: "one", nil: "none"}
    m[false] = "no"
    print(m, m[true], m[1], nil in m, keys(m))

prints

    {true: "yes", 1: "one", nil: "none", false: "no"} yes one true [true, 1, nil, false]

---

    let m = {"nil": 1}
    print(m[nil])

prints

    runtime error at 2:8: key nil not found

---

    print(get({false: 0}, false), get({}, [1], 0))

prints

    runtime error at 1:34: get: argument 2 must be a string, int, bool or nil, got array
