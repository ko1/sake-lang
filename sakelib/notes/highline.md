# highline

`require "highline"` → `sakelib/highline.sake`, a subset of the highline gem (2.x; not installed here, so
the twin is the plain-Ruby reference `test/sakelib/ref/highline.rb`, written from memory of the gem's
QuestionAsker / Question / Menu: the flow is the gem's, the message texts are as I remember them and
are not verified against the gem). Test: `test/sakelib/highline.{sake,rb}`, 44 identical lines; the
answers come from a StringIO in both programs. 9 operations: `new`, `say`, `newline`, `list`, `ask`,
`ask_integer`, `ask_float`, `agree`, `choose` (and the readers `input`, `output`).

## API

| Ruby (highline) | Sake | |
|---|---|---|
| `HighLine.new(input, output)` | `HighLine.new(input, output)` | same; IO or StringIO (`require "stringio"`); defaults `IO.stdin`, `IO.stdout` |
| `cli.say("Hi")` / `cli.say("Name? ")` | `HighLine.say(cli, s)` | same (a trailing space or tab: no newline) |
| `cli.newline` | `HighLine.newline(cli)` | same |
| `cli.list(items, :rows)` | `HighLine.list(cli, items)` | `:rows` only |
| `cli.ask("Name? ")` | `HighLine.ask(cli, "Name? ")` | same, a String |
| `cli.ask(q) { \|q\| q.default = "Tokyo" }` | `HighLine.ask(cli, q, default: "Tokyo")` | differs: a keyword, not a block; shown as `\|Tokyo\|` as the gem |
| `cli.ask(q) { \|q\| q.validate = /re/ }` | `HighLine.ask(cli, q, validate: /re/)` | differs: a keyword |
| `cli.ask(q, Integer)` / `(q, Float)` | `HighLine.ask_integer(cli, q)` / `ask_float` | differs: the type picks the operation |
| `{ \|q\| q.in = 0..120; q.above = 0; q.below = 10 }` | `range: 0..120, above: 0, below: 10` | differs: keywords; `in` is a reserved word |
| `cli.agree("Continue? ")`, with `q.default = "no"` | `HighLine.agree(cli, q, default: "no")` | same flow (re-asks the question) |
| `cli.choose { \|m\| m.header = "Fruits"; m.prompt = "? "; m.choices("a", "b") }` | `HighLine.choose(cli, String["a", "b"], header: "Fruits", prompt: "? ")` | differs: the items are an Array, the settings keywords; returns the item |
| `menu.choice("a") { action }` | — | missing: a block per item cannot be stored; `case` on the result |
| `q.echo = false`, `q.character = true` (passwords, one key) | — | missing: needs the terminal's raw mode |
| `q.confirm`, `q.limit`, `q.whitespace`, `q.case`, `q.gather`, `q.readline`, `q.completion`, `q.answer_type = [choices]` | — | missing (subset) |
| `menu.index = :letter`, `layout`, `select_by`, `shell`, `nil_on_handled` | — | missing (subset) |
| `cli.color(s, :red)`, `HighLine.color`, `use_color` | — | missing: use `colorize.sake` |
| `cli.indent`, `cli.wrap`, ERB in statements, `HighLine::Paginator` | — | missing |

## できたこと / できなかったこと

- Ported: the question flow of the gem's `QuestionAsker` as I know it: say the question (with the default
  appended as `|default|`), read a line (`EOFError`, "The input stream is exhausted." at the end), strip,
  take the default for an empty answer, validate (a Regexp), convert, check the range; on an error print
  the response and then `"?  "` and read again (for `agree`, the question again); `choose` lists
  `1. apple` lines under an optional `header:`, accepts a number, a name, or a unique prefix in any case,
  and says `You must choose one of [1, 2, 3, apple, banana, cherry].` or `Ambiguous choice.  Please choose
  one of [...]` otherwise.
- **A type as an argument.** `ask(q, Integer)` returns an Integer because Integer was passed; a type is not
  a value in Sake, and the result type of one `ask` would be `String | Integer | Float` for every caller.
  So `ask` (String), `ask_integer`, `ask_float`. The checker types each: `n = HighLine.ask(cli, "N? "); n +
  1` → `Arithmetic.+: the operands are (String, Integer) ... [type]` before running. (A probe showed the
  checker specializes a call by a Symbol literal argument, so `ask(cli, q, type: :integer)` would also have
  typed Integer at each call; the separate names are closer to how a reader thinks.)
- **The Question block.** `ask(q) { |q| q.default = ...; q.validate = ... }` configures an object in a block.
  Blocks cannot be stored, and there is nothing to call on `q`; the settings are keyword parameters. The
  Menu block likewise: the items are an Array and `header:` / `prompt:` keywords. `menu.choice(name) {
  action }` has no counterpart: `choose` returns the item and the caller branches.
- `q.in = 0..120` is `range:` here: `in` is a reserved word, so it cannot be a readable parameter.
- Terminal modes (`echo = false` for a password, `character = true` for one keystroke) need `IO.raw` /
  `IO.noecho`: not available, so not ported.
- Colours: HighLine's `color` is the same ANSI scheme as colorize; `colorize.sake` covers it.

## 書き心地

- The library passed `--strict` on the first run and the outputs matched on the first comparison after one
  fix in the **Ruby** reference (`case answer_type when Integer` compares a class with a class and never
  matches: `Integer === Integer` is false). The side without a checker was the side with the bug.
- `v = Integer(answer) rescue nil` then `if v == nil ... next end`, and `v` is an Integer below: the
  `rescue` modifier plus the nil test narrowed as expected, and `break v` typed the `loop`'s result as
  Integer. `ask_integer` and `ask_float` are the same twelve lines twice; a shared body would have given one
  result type `Integer | Float` to both.
- `complete(choices, s)` returns the index, `:ambiguous`, or nil, and the caller does `case found in nil ...
  in :ambiguous ... in Integer ... break Array.fetch(items, ...)`: the three outcomes are the three
  branches, and the typer saw the case as complete. The Ruby reference encodes the same three outcomes as
  two `ArgumentError` messages matched by regexp, as the gem does (`/ambiguous/`, `/invalid value for/`).
- `_, i = Array.fetch(found, 0)` takes the `[String, Integer]` Tuple of `each_with_index` apart; `found`
  came from `Array.select(Array.each_with_index(choices)) { |c, i| ... }`, Ruby's `each_with_index.select`
  with the enumerator spelled as an Array. Fine.
- Three stream helpers (`write`, `writeln`, `read_line`) each hold a two-branch `case i in IO ... in StringIO`
  because `(IO|StringIO).gets(i)` is rejected (`IO` is not a type in a type list; repro in
  `ruby_progressbar_bug_io_in_type_list.sake`). Nine lines of boilerplate for "an input is an IO or a StringIO".
- `append_default` is the gem's five-way `if` on the question's last characters, with `String.match(question,
  /([\t ]+)\z/)` and `m[1]` for Ruby's `$1`: the same shape, one local more.
- What the keywords bought: `HighLine.ask_integer(cli, "Age? ", rnage: 0..120)` is a static error with a hint; in
  the gem a misspelled `q.rnage = ...` is `NoMethodError` the first time that line runs, after the user has
  typed the answer.

## Built-ins requested

- `IO.tty?(io)`: HighLine (and ruby-progressbar) decide their behaviour by it.
- `IO.raw(io) { }` / `IO.noecho(io) { }` / `IO.getch(io)`: `q.echo = false` (passwords) and `q.character`.
- `IO` in a type list `(IO|StringIO).gets(i)`: the stream `case`s above.
