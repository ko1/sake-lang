# Change: keys without a value

A configuration line that, after trimming, is only a valid name (no `=`), such as `password`, now
declares that key in the current section **without a value**. This is
different from `KEY =`, whose value is the empty text.

A declaration without a value behaves like any other key line for sections and duplicates: it
creates the key, and if the section already has the key it replaces the old value (the key then has
no value) and prints `line N: duplicate key SECTION.KEY`. A later `KEY = VALUE` gives it a value
again, with the same duplicate message.

- `GET` of such a key prints `SECTION.KEY: no value`.
- Resolving: a reference to a key without a value fails with `no value SECTION.KEY`. It is checked
  right after the `undefined` check for that reference, so problems are still reported in the
  order they are met, left to right.
- `KEYS`: keys are still sorted by name in byte order; a key without a value is printed with `?`
  directly after its name.

Everything else is unchanged.

## Example 1

Input:
```
[db]
host = db.local
password
url = ${host}:${password}
empty =
%%
GET db.host
GET db.password
GET db.url
GET db.empty
KEYS db
```
Output:
```
db.host = str "db.local"
db.password: no value
db.url: error: no value db.password
db.empty = str ""
db: empty, host, password?, url
```

## Example 2

Input:
```
timeout = 30
timeout
retries
retries = 3
Port
[s]
t = ${main.timeout}
%%
GET timeout
GET retries
GET s.t
KEYS main
```
Output:
```
line 2: duplicate key main.timeout
line 4: duplicate key main.retries
line 5: syntax error
main.timeout: no value
main.retries = int 3
s.t: error: no value main.timeout
main: retries, timeout?
```
