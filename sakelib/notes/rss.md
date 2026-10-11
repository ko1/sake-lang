# rss (RSS::Parser, RSS::Maker)

`require "rss"` → `sakelib/rss.sake` (on `sakelib/xml.sake` for parsing and `sakelib/time.sake` for dates).
Test: `test/sakelib/rss.{sake,rb}` (identical output: two feeds parsed and printed field by field,
regenerated with `to_s`, two feeds made, round trips, errors). Ported from the rss gem 0.3.2: RSS 2.0
(with 0.9x's elements) and Atom 1.0, parsing and making.

## API

| Ruby | Sake | |
|---|---|---|
| `RSS::Parser.parse(xml)` / `parse(xml, false)` | `RSS::Parser.parse(xml)` / `parse(xml, false)` | same; the result is `RSS::Rss \| RSS::Atom::Feed \| nil`, so the caller narrows (`feed => RSS::Rss`) |
| `rss.feed_type`, `feed_version`, `rss_version`, `rss.channel`, `rss.items`, `rss.image` | `RSS::Rss.feed_type(rss)` … | same |
| `channel.title`, `link`, `description`, `language`, `copyright`, `managingEditor`, `webMaster`, `rating`, `docs`, `generator`, `ttl` (Integer) | `RSS::Rss::Channel.title(ch)` … | same |
| `channel.pubDate`, `lastBuildDate`, `date` (Time) | same | same |
| `channel.image.url/title/link/width/height/description` | `RSS::Rss::Channel::Image.url(im)` … | same |
| `channel.items`, `channel.categories` | same | same |
| `item.title`, `link`, `description`, `author`, `comments`, `pubDate`, `date`, `categories`, `source`, `enclosure`, `guid` | `RSS::Rss::Channel::Item.title(item)` … | same |
| `category.domain/content`, `enclosure.url/length/type`, `source.url/content` | `RSS::Rss::Channel::Item::Category.domain(c)` … | same |
| `guid.content`, `guid.isPermaLink`, `guid.PermaLink?` | `RSS::Rss::Channel::Item::Guid.content(g)` … | same |
| `feed.title.content`, `feed.title.type`, `subtitle`, `rights` | `RSS::Atom::TextConstruct.content(RSS::Atom::Feed.title(f))` … | differs: one `TextConstruct` class for Ruby's `Feed::Title`, `Feed::Subtitle`, `Entry::Summary`, … |
| `feed.id.content`, `icon`, `logo`, `author.name.content`, `uri`, `email` | `RSS::Atom::Value.content(...)` | differs: one `Value` class (Ruby: `Feed::Id`, `Feed::Author::Name`, …) |
| `feed.updated.content`, `entry.published.content` | `RSS::Atom::DateConstruct.content(...)` | differs: same reason |
| `feed.authors`/`author`, `contributors`, `categories`, `links`/`link`, `generator`, `entries`/`items` | `RSS::Atom::Feed.authors(f)` … | same; the element classes are `RSS::Atom::PersonConstruct`, `Category`, `Link`, `Generator` |
| `entry.title`, `id`, `updated`, `published`, `summary`, `content` (`type`, `src`, `content`), `links`, `authors`, `categories`, `rights` | `RSS::Atom::Feed::Entry.title(e)` … | same (content is `RSS::Atom::Content`) |
| `feed.to_s` / `rss.to_s` | `puts(feed)`, `RSS::Rss.to_s(rss)` | same text as the gem for the elements ported |
| `RSS::Maker.make("2.0") { \|maker\| ... }`, `make("atom")` | `RSS::Maker.make("2.0") { \|maker\| ... }` | same; result `RSS::Rss \| RSS::Atom::Feed` |
| `maker.channel.title = "x"` | `ch = RSS::Maker::RSSBase.channel(maker)` / `ch.RSS::Maker::ChannelBase.title = "x"` | differs: no calls on values |
| `maker.channel.` `link description language copyright managingEditor webMaster updated/pubDate/date lastBuildDate docs generator ttl about/id author subtitle rights icon logo` | `RSS::Maker::ChannelBase.<name>` and `set_<name>` | same |
| `maker.channel.links.new_link { \|l\| }`, `categories.new_category { \|c\| }` | `RSS::Maker::LinksBase.new_link(RSS::Maker::ChannelBase.links(ch)) { \|l\| }` … | same |
| `maker.items.new_item { \|item\| }` | `RSS::Maker::ItemsBase.new_item(RSS::Maker::RSSBase.items(maker)) { \|item\| }` | same |
| `item.title link description author comments updated/pubDate/date summary id`, `item.guid.content/isPermaLink`, `item.categories.new_category`, `item.enclosure.url/length/type` | `RSS::Maker::ItemBase.<name>`, `RSS::Maker::GuidBase.content` … | same |
| `RSS::MissingTagError`, `NotWellFormedError`, `NotAvailableValueError`, `NotSetError`, `UnsupportedMakerVersionError` | same names | same messages (NotWellFormedError's is the XML parser's) |
| RSS 1.0 (`rdf:RDF`, `make("1.0")`), 0.91/0.92 makers, `xml-stylesheet`, the modules (dc:* beyond dc:date, content:encoded, itunes:*, slash, taxonomy, trackback, image), `textInput`, `cloud`, `skipDays`/`skipHours`, `items.do_sort`, `RSS::Parser` options and listeners, `to_feed`/`setup_maker` conversions, `xml:lang`/`xml:base` | — | missing |

About 60 readers and writers on 25 classes, plus `parse`, `make`, `to_s`.

## What differs and why

- **Element classes.** The gem generates a class per element (`install_text_element`, `module_eval` of
  method sources) and a maker class per version. Sake has neither `module_eval` nor `define_method`, so
  each element is a class with its fields written out. Atom's per-element classes, all alike, are a few
  shared construct classes (named after the gem's mixins `TextConstruct`, `DateConstruct`,
  `PersonConstruct`); the makers are one set (`ChannelBase`, `ItemBase`, ... the gem's base classes).
  Ruby nests `ItemBase` inside `ItemsBase`; here they are side by side in `RSS::Maker`.
- **Writers.** Ruby's `maker.channel.title = "x"`: Sake writes the chain form `ch.RSS::Maker::ChannelBase.title
  = "x"`, which needs the channel in a local first. The namespace is repeated on every line; that is the
  biggest difference in the test.
- **nil.** Ruby's `feed.title.content` assumes the title exists (it is required); in Sake each optional
  element is `nil | T` and `--strict` asks for a check, so the test introduces a local per step and
  asserts it (`title => RSS::Atom::TextConstruct`). The Ruby test was given the same locals to stay
  line-parallel.
- **The result of parse/make** is a union (`RSS::Rss | RSS::Atom::Feed`); Ruby uses duck typing
  (`feed.items` works on both). Here `RSS::Atom::Feed.items(f)` exists, but the caller narrows first.
- **Dates in `to_s`** are written in UTC (rfc822 with `-0000`, w3cdtf with `Z`). The gem converted the
  parsed `+0900` dates of the test documents to UTC on this machine (and kept the offset for a
  document without an XML declaration, which the test does not use).
- **Validation** checks the required children (`channel`: title, link, description; `image`: url, title,
  link; Atom `feed` and `entry`: id, title, updated) and the date formats; the gem's full content-model
  validation (order, multiplicity, unknown elements in strict mode) is not done. Unknown elements are
  ignored, as the gem's default.
- The maker leaves out an RSS item with neither title nor description and an Atom entry without an id
  (or link) or title, as the gem does silently.

## Built-ins Sake lacks (requests)

- `Time.rfc2822` / `Time.xmlschema` in time.sake are parser and formatter in one (String or Time in);
  the result types `String | Time`, so the writer formats with `Time.strftime` / built-in
  `Time.iso8601` instead. Separate formatter names would help.
- `CGI.escapeHTML` as a built-in String operation (written as a `gsub` with a Hash).

## Friction

- `def uri = "..."` in `module Atom` (which also holds classes) → `RSS::Atom.uri is a mixin function: it
  has no subject to dispatch on` → `module_function` at the top of the module. The hint said exactly that.
- `RSS::Maker::GuidBase.new` for a builder whose fields start empty → `wrong number of arguments for
  RSS::Maker::GuidBase.new (given 0, expected 2)` → an empty `def initialize(x) end` makes every field
  optional. Seven classes needed it; the cost of "without initialize every field is required".
- `text(out, i, "dc:date", Time.xmlschema(t))` → `String.gsub: argument 1 must be String, but is Time`,
  reported in `h()`, six calls deep, with the chain in the hint → `Time.iso8601`. The union came from
  time.sake's two-way function.
- In the test I first wrote `RSS::Atom::Feed::Entry.title(entry) || RSS::Atom::TextConstruct.new` to get past
  the nil check in one line; it hid the point and needed a no-arg `new`, so the test uses `x => T` locals.
- What went well: the first complete run printed the same 212 lines as the gem, including the gem's
  attribute-per-line layout, CGI escaping and element order; the work was finding the gem's rules by
  running it (element order follows the install order in 0.9.rb + 2.0.rb, not the document).

## Size

Ruby (non-blank, non-comment lines) of the parts ported: rss.rb 1174, parser.rb 483, 0.9.rb 346,
2.0.rb 86, atom.rb 634, maker/base.rb 776, maker/2.0.rb 189, maker/atom.rb 153, maker/feed.rb 363,
maker/entry.rb 140 (about 4300 lines, much of them generic machinery for features not ported).
Sake: 656 lines (796 with comments and blank lines). Tests: 251 lines Ruby, 287 Sake.
