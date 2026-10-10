# mustache

`sakelib/mustache.sake` is a Mustache template engine after the mustache gem's
`Mustache.render(template, view)`; the reference is `test/sakelib/ref/mustache.rb`.
`test/sakelib/mustache.sake` prints the same 46 lines as `mustache.rb`. 179 lines, 13 functions.

## API

| Ruby (mustache gem) | Sake | |
|---|---|---|
| `Mustache.render(template, hash)` | `Mustache.render(template, view)` | same (String or Symbol keys) |
| partials: subclass overriding `partial(name)`, or `template_path` files | `Mustache.render(t, view, partials: Hash["name" => "..."])` | differs (a keyword Hash) |
| `{{x}}`, `{{{x}}}`, `{{& x}}`, `{{a.b}}`, `{{.}}`, `{{#s}}`, `{{^s}}`, `{{! c}}`, `{{> p}}` | same | same, with the spec's standalone lines and partial indentation |
| `Mustache::Parser::SyntaxError` | `Mustache::Parser::SyntaxError` | same name (nested since 2026-10-10; was `MustacheSyntaxError`); messages are this port's own |
| view classes (`class Simple < Mustache; def name`), lambdas, `{{=<% %>=}}` | | missing |

Escaping is `CGI.escapeHTML`'s (`&amp; &lt; &gt; &quot; &#39;`). Sections: false/nil/`[]` skip, an Array
iterates, a Hash or any other truthy value is pushed once as the context.

## What differs, and why

- View classes need receiver dispatch (`view.send(name)`), which Sake rejects; views are Hashes.
- Partials come from a `partials:` Hash, since there is no subclass to override `partial`.

## Frictions

1. `case Mustache::Node.kind(node)` without `else` → `case/in: no in branch matches :root [type]`. Correct:
   the kind field also holds the root's `:root` → `else nil`.
2. A recursive partial test whose leaves had no `kids` key looked `kids` up in the outer context and
   recursed forever (my test's bug; Ruby stops with `SystemStackError` in 0.3 s). Sake ran 60 s / 3 GB
   without reaching its 10,000-call limit: each level scans the context stack (quadratic), and each
   interpreted call is slow, so the limit is far away in time. Not a Sake bug; the test now ends the
   recursion with `"kids" => false`.

## New language features used

- `T.new` keywords: `Mustache::Node.new(kind, name, indent:)`; defaults `text = ""`, `indent = ""`,
  `children = Mustache::Node[]` (a fresh typed Array per node). Helped.
- `initialize` checks `@kind => Symbol`, `@name => String`; `render` asserts `template => String`,
  `partials => Hash`.
- Optional positional + keyword: `def render(template, view = Hash[], partials: Hash[])`, as the gem's
  `render(data = template, ctx = {})`.
- `once` for the sigil and escape tables; `private attr_accessor pos = 0`.
- `first, *rest = String.split(name, ".")` for dotted names.
- `**opts`, `block_given?`, `&b`: not needed.

## Checker findings

- `--strict=1`: the `:root` exhaustiveness report above.
- `--strict=2`: none.

## Types (`--types`)

- `Mustache::Node.kind`: `:inverted | :partial | :raw | :root | :section | :text | :var` (all literal
  Symbols, so the `case` is checked for completeness). No unions elsewhere; the view's values are the
  recursive union the test builds, reached through `case` / `in Hash` / `in Array`.
