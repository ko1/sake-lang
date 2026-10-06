# Config file with references

Read an INI-style configuration, then answer queries about it.

## Input (standard input)

Configuration lines come first, up to a line `%%`; query lines follow. Each line is trimmed of
leading and trailing spaces before it is examined. Line numbers N count every input line from 1.

Configuration lines:

- Empty lines, and lines starting with `#` or `;`, are ignored.
- `[NAME]` starts section NAME. A name is one or more of `a-z`, `0-9`, `_`. A section may appear
  again; its keys continue. Keys before any section header belong to section `main`.
- `KEY = VALUE`: split at the first `=`; KEY (trimmed) must be a valid name, VALUE is trimmed and may
  be empty. If the section already has KEY, the new value replaces it and `line N: duplicate key
  SECTION.KEY` is printed.
- Anything else prints `line N: syntax error`.

A value may contain references `${KEY}` or `${SECTION.KEY}` (names as above); any other text,
including a malformed `${...}`, is literal. `${KEY}` means KEY in the same section as the value
containing it. To resolve a key, replace each reference, left to right, by the resolved text of the
key it names. Resolving fails with the first problem met in that order: a reference to a missing key
gives `undefined SECTION.KEY`; a reference back to a key already being resolved gives `cycle A -> B ->
... -> A`, listing every key from the queried one to the repeated one.

Queries (empty lines ignored; words separated by spaces):

- `GET NAME`: NAME is `SECTION.KEY`, or `KEY` meaning `main.KEY`. Print `SECTION.KEY = TYPED` for a
  resolved value, `SECTION.KEY: error: PROBLEM` when resolving fails, and `SECTION.KEY: not found`
  when the key does not exist.
- `KEYS SECTION`: print `SECTION: ` followed by its keys in byte order, joined by `, `, or `(none)`.
  A section exists if it had a header or a key; otherwise print `SECTION: not found`.
- Anything else prints `line N: bad query`.

TYPED, for the resolved text V, by the first rule that applies:

1. V is an optional `+`/`-` and digits: `int ` and the integer in normal form (`+007` is `7`, `-0` is `0`).
2. V is `true`, `yes`, `on` (any letter case): `bool true`; `false`, `no`, `off`: `bool false`.
3. V contains a comma: split at commas, trim each item, drop empty items; print `list[COUNT]`,
   then, if COUNT > 0, a space and the items joined by ` | `.
4. Otherwise `str "V"`.

Configuration messages appear in input order, before query answers. At most 200 lines.

## Example 1

Input:
```
host = example.org
[server]
port = 08080
url = http://${main.host}:${port}/
debug = Yes
[db]
hosts = a, ,b,
%%
GET server.url
GET server.port
GET server.debug
GET db.hosts
GET host
```
Output:
```
server.url = str "http://example.org:08080/"
server.port = int 8080
server.debug = bool true
db.hosts = list[2] a | b
main.host = str "example.org"
```

## Example 2

Input:
```
[a]
x = ${y}
y = ${b.z}-${x}
w = ${nope}
[b]
z = 1
z = 2
oops
%%
GET a.x
GET a.w
GET b.z
GET q
KEYS a
KEYS c
LIST a
```
Output:
```
line 7: duplicate key b.z
line 8: syntax error
a.x: error: cycle a.x -> a.y -> a.x
a.w: error: undefined a.nope
b.z = int 2
main.q: not found
a: w, x, y
c: not found
line 16: bad query
```
