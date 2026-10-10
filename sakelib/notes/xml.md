# xml

`sakelib/xml.sake` is a subset of REXML (rexml 3.4.4): parse a document, read it through
`Document#root`, `Element#elements` / `attributes` / `text`, and select elements with simple XPath. The
test is compared with Ruby's REXML: `test/sakelib/xml.sake` prints the same 78 lines as `xml.rb`.
442 lines, 70 functions.

## API

| Ruby (REXML) | Sake | |
|---|---|---|
| `REXML::Document.new(str)` | `REXML::Document.new(str)` | same (`initialize` parses) |
| `doc.root`, `doc.version`, `doc.encoding`, `doc.children`, `doc.elements`, `doc.to_s` | `REXML::Document.root(doc)`, ... | same |
| `el.name`, `el.attributes["k"]`, `el["k"]`, `el.attributes.each { \|k, v\| }` | `REXML::Element.name(el)`, `REXML::Element.attributes(el)["k"]`, `el["k"]`, `Hash.each(...)` | same; `attributes` is a Hash of String values (REXML's holds Attribute objects) |
| `el.elements[1]`, `el.elements["a/b"]`, `el.elements.each("b") { }`, `to_a`, `size` | `es[1]`, `es["a/b"]`, `REXML::Elements.each(es, "b") { }`, ... | same (`REXML::Elements` includes `Indexable`) |
| `el.text`, `el.text("path")`, `texts`, `cdatas`, `comments`, `children` | same, `REXML::Element.text(el, "path")` | same |
| `el.has_elements?`, `has_text?`, `has_attributes?`, `parent`, `root`, `each_element`, `get_elements` | same | same |
| `REXML::XPath.match(node, p)`, `first`, `each` | `REXML::XPath.match(node, p)`, ... | same for the subset below |
| `Element.new(name)`, `add_element(name, attrs)`, `add_attribute`, `add_text`, `el.to_s` | same | same |
| `REXML::ParseException` | `REXML::ParseException` | differs (name; messages are this port's own) |
| `el[i] = node` (`Parent#[]=`), `delete_element`, `Attribute` objects, namespaces, entity declarations, `Formatters::Pretty`, SAX/stream parsers | | missing |

XPath: absolute and relative paths of `name`, `*`, `.`, `..` steps joined by `/` and `//`, with
predicates `[n]`, `[last()]`, `[@a]`, `[@a='v']`, `[child]`; positions count among the parent's
children that pass the test, as XPath's. It selects elements only (no `@attr` or `text()` steps).

## What differs, and why

- Names: REXML's own, nested in `module REXML` since 2026-10-10 (`REXMLDocument`, `REXMLElement`, ... before):
  `REXML::Document`, `REXML::Element`, `REXML::Elements`, `REXML::Text`, `REXML::CData`, `REXML::Comment`,
  `REXML::XMLDecl`, `REXML::XPath`, `REXML::ParseException`; a DOCTYPE or a processing instruction is a
  `REXML::Instruction` kept as written. The parser is `REXML::Parser`, this port's own (REXML's are
  `REXML::Parsers::BaseParser` / `TreeParser`, a different shape).
- `REXML::Element#==` compares name, attributes and children; REXML compares identity. Elements have a
  `parent` field, so Struct's own `==` (all fields) would recurse through the cycle; the type defines
  `==`. Sake has no identity comparison, so the XPath code never asks "is this the same element": it
  counts positions while walking the tree.
- `Element#attributes` is a plain `Hash[String => String]`: REXML's `Attributes` gives the same `[]` and
  `each`, which is how it is used.
- Error messages are this port's own (REXML's carry the parser's position and unconsumed text); the
  test prints only that the exception was raised, for 9 malformed documents (all of which REXML rejects
  too). Undefined entities (`&foo;`) stay as written, as REXML does.

## Frictions

1. `Array.select(@children) { |c| c in REXML::Element }` and `Array.find` keep the element type of the
   whole children Array, so every use reported `REXML::Element.name: argument 1 must be REXML::Element, but
   can be REXML::CData | REXML::Comment | ... [mixed]` (9 warnings at level 1, errors at level 2) →
   `Array.filter_map(@children) { |c| (c in REXML::Element) ? c : nil }`, whose ternary narrows. This cost
   the most; a narrowing `select`/`find`/`grep(T)` would read better.
2. `def until(rp, s, what)` → 25 Prism syntax errors (`unexpected write target`, `expected an end to
   close the until statement`); `until` is a keyword, as in Ruby → `read_until`.
3. `REXML::Element.name(@parent)` after `@parent == nil ||` → `[nil]` (fields are not narrowed) → copy to a
   local first.
4. Positional predicates first compared candidates with `==` to find "this element" among its
   siblings; with content equality two equal `<tag/>`s are the same → rewrote as a walk that counts.
5. REXML details found only by running it: `CData#to_s` is the bare value and `Comment#to_s` the bare
   string (the delimiters appear only inside `Element#to_s`), whitespace after the root element and after
   a DOCTYPE is dropped, `Element#[]=` sets a child (not an attribute), there is no `root?`.

## New language features used

- `initialize` for parsing: `REXML::Document.new(str)` parses in `initialize` into
  `private attr_reader node = REXML::Element.new("")` (an expression default: a fresh container per
  document). Helped: the call reads as Ruby's.
- `T.new` keywords: `REXML::Element.new(name, attrs, parent: cur)`; defaults `attributes = Hash[]`,
  `children = Array[]`, `parent = nil`.
- `x => T` where REXML raises: `@name => String`, `add_attribute`'s `k => String`, `v => String`.
- Optional positional parameters: `text(el, path = nil)`, `each(es, path = "*")`,
  `add_element(el, name, attrs = Hash[])`, as REXML's.
- `once` for the entity table; `include Indexable` with `def [](el, k)` taking a String (attribute) or an
  Integer (child), narrowed by `case k in String / in Integer`.
- `*rest`, `**opts`, `block_given?`, `&b`: not needed.

## Checker findings

- `--strict=1`: 9 `[mixed]` warnings (friction 1).
- `--strict=2`: those 9 as errors, the `[nil]` of friction 3, and a `case/in` that may get nil reached
  from the test (`es["magazine/title"]`, which may be nil, passed on unchecked); the test now checks it.

## Types (`--types`)

- `REXML::Element.children`: `Array[REXML::CData | REXML::Comment | REXML::Element | REXML::Instruction |
  REXML::Text | REXML::XMLDecl]`: a mixed node list, as REXML's; readers narrow with `in`.
- `REXML::Element.parent`: `nil | REXML::Element` (a detached element or the document's container has none).
- `REXML::XMLDecl.encoding`: `nil | String` (optional in the declaration).
- No `partial` or `unknown` checks.
