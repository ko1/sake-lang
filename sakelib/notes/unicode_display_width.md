# unicode_display_width (Unicode::DisplayWidth)

`require "unicode_display_width"` → `sakelib/unicode_display_width.sake`. Test:
`test/sakelib/unicode_display_width.{sake,rb}` (identical output; the .rb uses unicode-display_width 3.2.0
with unicode-emoji 4.2.0).

## Where the data comes from (nothing is copied into the .sake)

- **Width index**: the gem's `data/display_width.marshal.gz`, read at run time. `Zlib.gunzip` + a small
  reader for the part of Ruby's Marshal format the file uses (Hash, Symbol and symbol links, Array,
  Integer, nil, String with ivars). Instead of rebuilding the gem's nested trie (17 planes, then 16-way
  levels down to single codepoints; a nested Array of Integer|nil|Array has no type in Sake), the reader
  walks the trie and emits flat sorted ranges `[start, width]` (merged when equal), looked up with
  `Array.bsearch_index`. Same answers, including the gem's `nil` → width 1 and its 4096-entry fast table
  (codepoint 0x1000 falls just past it and counts 1). Found via `UNICODE_DISPLAY_WIDTH_DATA` or `gem which
  unicode/display_width`. Loading takes ~2.5 s of CPU (once; only for non-ASCII input).
- **Emoji regexps**: unicode-emoji's `lib/unicode/emoji/generated/regex_*.rb` (TEXT_PRESENTATION,
  EMOJI_KEYCAP, INCLUDE_MQE_UQE, WELL_FORMED); the one regexp literal in each file is cut out of the source
  and given to `Regexp.new`. Found via `UNICODE_EMOJI_DIR` or `gem which unicode/emoji`. Ruby's gem picks
  `generated_native/` (property classes like `\p{Emoji}`) when Ruby's Unicode emoji version matches; the
  port always uses `generated/` (explicit lists), which matches the gem's own data whatever Ruby's Onigmo knows.

## API

| Ruby | Sake | |
|---|---|---|
| `Unicode::DisplayWidth.of(s)` | `Unicode::DisplayWidth.of(s)` | same |
| `Unicode::DisplayWidth.of(s, 2)` (ambiguous) | `Unicode::DisplayWidth.of(s, 2)` | same |
| `.of(s, emoji: :all, overwrite: {0x2588 => 2}, ambiguous: 2)` | `.of(s, {emoji: :all, overwrite: Hash[0x2588 => 2], ambiguous: 2})` | differs: options Record |
| `.of(s, 1, {}, emoji: :all)` | `.of(s, 1, {emoji: :all})` | differs: no old positional `overwrite`/`old_options` |
| emoji modes `true :auto nil false :none :all :all_no_vs16 :vs16 :rgi :rgi_at :possible` | same | same |
| `DisplayWidth.new(ambiguous: 2, overwrite: {}, emoji: :all)` | `Unicode::DisplayWidth.new(ambiguous: 2, emoji: :all)` | same |
| `dw.of(s, **kwargs)` | `Unicode::DisplayWidth.of(dw, s, {...})` | same (one `of` for both, see below) |
| `DisplayWidth::EmojiSupport.recommended` | same | same (reads `CI`, `TERM_PROGRAM`, `TERM`, `WT_SESSION`) |
| `VERSION`, `UNICODE_VERSION`, `DEFAULT_AMBIGUOUS` | `Unicode::DisplayWidth.VERSION` ... | functions |
| `width_ascii`, `width_custom`, `emoji_width`, `emoji_width_via_possible`, `decompress_index` | `width_ascii` ... (no `decompress_index`) | internal |
| `require "unicode/display_width/string_ext"` (`"x".display_width`) | — | missing: no methods on String |
| `reline_ext` | — | missing: no Reline |
| binary / non-UTF-8 input (`encode(... invalid: :replace)`) | — | missing: Sake Strings are UTF-8 |

10 operations ported (of, new, the instance fields, EmojiSupport.recommended, the 3 constants, and the
internal helpers).

## What differs, and why

- **One `of` for the class and the instance.** Ruby has `DisplayWidth.of(string, ...)` and `dw.of(string,
  ...)`; one name is one function, so `of` dispatches on its first argument (a String or a DisplayWidth).
  Its second argument is the ambiguous width or the options Record.
- **Options Record** instead of keywords (the convention for Sake functions): `{emoji: :all}`. Ruby's
  deprecated positional `overwrite` and `old_options` Hash (which only warn) are not taken.
- `EmojiSupport.recommended` keeps the gem's `:rqi` under `CI` (a misspelling of `:rgi`, which therefore
  counts no emoji); a test that must not depend on the terminal passes `emoji:` explicitly.

## Built-ins Sake lacks

- `Marshal.load` (the gem's data is a Marshal dump; read here by ~120 lines of Sake).
- Finding an installed gem's files (`Gem::Specification`/`__dir__` of another library): `gem which`.

## Friction

- None in the checker this time worth a repro; the code ran and matched Ruby on the first full run.
  The constant-as-function rule again: `REGEX_EMOJI_VS16` inside the class needs `DisplayWidth.`.
- The trie is a recursive type (`Array` of `Integer | nil | Array`), which Sake cannot express; flattening it
  while reading was simpler than any typed tree, and faster to look up.

## Size

Ruby: 258 code lines (346 with comments) in display_width.rb, constants.rb, emoji_support.rb, index.rb
(plus the unicode-emoji regexps, read as data). Sake: 318 code lines (379 with comments), of which ~120
are the Marshal reader that replaces `Marshal.load`.
