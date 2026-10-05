# REVIEW (02-analytics, corpus-v3, 2026-10-05)

The Ruby versions were read from `experiments/2026-10-01-inference-500/corpus/02-analytics/` (the
`.rb` symlinks in corpus-v3 point to `../../corpus/`, which does not exist here). All 25 programs
print their `.out` exactly with `bin/sake --strict=0`, exit 0.

## Per program

- access_log_urls: `class Request` + `attr_reader` (was `Struct.new`); `class BadLine < Exception` + `attr_reader line` (was `Exception.new(:line)`); unused `partition` parts bound to `_`.
- anagram_groups: unused block parameters written `_` as in Ruby (`|_, ws|`, `|k, _|`). Otherwise unchanged.
- autocomplete: `class Node` + `attr_accessor children, count, word` (Ruby's accessor; `insert` writes another node's fields with `set_word`); `collect` and `size` use `@word`/`@count`/`@children` instead of `get_x(node)`.
- caesar_crack: `|_, s|` in `min_by`. Otherwise unchanged.
- cooccurrence_pmi: block destructuring `|(a, b), c|` over the pair-keyed Hash (2 places) instead of `|key, c|` + `a, b = key`.
- csv_pivot: `class Sale` + `attr_reader` with `revenue` in the same class body; `class RowError < Exception` + `attr_reader line_no`.
- email_domains: `class Address` + `attr_reader user, domain` with its functions; `class InvalidAddress < Exception`; `base, _, tag =`; `|_, n|`.
- hashtag_trends: `class Post` + `attr_reader`; `|_, targets|`, `|_, n|`.
- inverted_index: `class Doc` + `attr_reader`; `class QueryError < Exception` + `attr_reader query`.
- kwic_concordance: `|w, (si, _)|` (as Ruby) instead of `|w, pos|` + `si, _ = pos`; `|w, _|`.
- language_guess: `|(g, _), i|` in `each_with_index` instead of `|pair, i|` + `g, _ = pair`; dropped an identity `Array.map { |g| g }` after `sort_by`.
- log_summary: `class Entry` + `attr_reader`; `|_, n|`.
- markov_text: `class Chain` + `attr_accessor order, table, starts` (Ruby's accessor); `weighted`/`generate`/`branching` read `@table`/`@order` instead of `get_table(chain)` and a local copy of the order; `_` for unused block params and `key, _ = busiest`.
- naive_bayes: `class Model` + `attr_reader` (fields only mutated in place); `log_prob`/`scores`/`indicative` use `@vocab`, `@word_counts`, `@totals`, `@class_docs`; misses filtered with `|(want, got), _|` and iterated with `|(want, got), n|` instead of `pair` + `want, got = pair` (2 places); `label, _ = best`.
- near_duplicates: unchanged.
- ngram_counts: `|(a, b), c|` in `successors`; `_` for unused block params.
- rake_keywords: `class Keyword` (`include Comparable`, `attr_accessor`, `<=>`, `to_s` in one body; was `Struct.new` + a later `class Keyword`); `class EmptyDocument < Exception` + `attr_reader name`; `|_, n|`.
- readability: `class Stats` + `attr_reader` with `reading_ease`/`grade`/`merge` in the same body; `|_, n|`.
- rhyme_scheme: `|_, ws|` (2 places). Otherwise unchanged.
- sentiment_lexicon: `class Review` + `attr_reader`; `class Score` + `attr_accessor` (written from `score_text`, as in Ruby); `|_, scores|`.
- soundex_index: `class Person` + `attr_reader`.
- spell_suggest: `w, _ = cache[t]`. Otherwise unchanged.
- tf_idf: `_` for unused block params (4 places). Otherwise unchanged.
- vocabulary_growth: `|(w, c), i|` in `each_with_index` instead of `|pair, i|` + `w, c = pair`; `|n, _|`, `|_, v|`.
- word_frequency: `|(w, c), i|` in `each_with_index` instead of `|wc, i|` + `w, c = wc`.

Count: 24 changed, 1 unchanged (near_duplicates). Of the 24, five changed only by writing `_`
for an unused block parameter or `partition` part (anagram_groups, caesar_crack, rhyme_scheme,
spell_suggest, tf_idf).
Features used: `class` + `attr_reader`/`attr_accessor` (13 programs), `class E < Exception`
(5), nested block destructuring `|(a, b), c|` (7). Not used, because nothing in this domain
called for them: optional/keyword parameters, `initialize`, `class B < A`, `x => T`, `once`,
`block_given?`, IO values. The Ruby versions have no `CONSTANT` tables (they use `def stopwords =
Set[...]` etc.), and no validation in `initialize`.

## Friction

- **Nested destructuring in multiple assignment.** ngram_counts.sake:70 wanted Ruby's
  `(a, b), c = best` (ngram_counts.rb:85); it is a static error
  (`` `(a, b)` cannot be assigned here ``), while the same shape is accepted as a block parameter
  (`|(a, b), c|`, ngram_counts.sake:35). Wrote `pair, c = best` then `a, b = pair`.
- **A class function on a value that is not the first parameter.** `@x` means the first
  parameter's field, so a function that walks from one instance to others still spells the
  accessors: autocomplete.sake:16-21 (`get_children(node)`, `set_word(node, ...)`,
  `set_count(node, get_count(node) + 1)` for Ruby's `node.word = phrase; node.count += 1`),
  markov_text.sake:18-21 and naive_bayes.sake:39-44 (a constructor-like `build`/`train` that
  fills a new instance), rake_keywords.sake:105, 133-134 and sentiment_lexicon.sake:53-55
  (`Keyword.set_score(merged, Keyword.get_score(merged) + Keyword.get_score(k))` for
  `merged.score += k.score`). There is no `+=` on a field of a value other than the first
  parameter.
- **Ruby's `self.build` / `self.empty` factory** (autocomplete.sake:11, markov_text.sake:12,
  naive_bayes.sake:36) becomes a class function whose first parameter is not an instance; that
  is fine, but it reads like an instance function, and `@x` inside it would silently mean a field
  of `words`/`examples`.
- **`max_by`/`sort_by` on a Set needs a dispatch list.** spell_suggest.sake:44 `(Set|Array).sort(cands)`
  for Ruby's `cands.to_a.sort` because `cands` is a Set on one path and an Array (`Set.select`
  returns an Array) on the other.
- **Min/max of two numbers.** kwic_concordance.sake:29-30 and autocomplete.sake:58 do
  `x = 0 if x < 0` for Ruby's `[x, 0].max`; `Array.max(Array[x, 0])` works but is heavier, and a
  Tuple `[x, 0]` has no `max`.

## Ruby comparison

- **`(h[k] ||= []) << v`.** Ruby's one-liner (autocomplete.rb:62, hashtag_trends.rb:40,
  kwic_concordance.rb:22, near_duplicates.rb:90, rhyme_scheme.rb:71, sentiment_lexicon.rb:103,
  soundex_index.rb:49) is kept in the Sake versions as two statements (`h[k] ||= Array[]` then
  `Array.push(h[k], v)`, e.g. soundex_index.sake:44-45). `Array.push(h[k] ||= Array[], v)` works
  in Sake; the two-statement form was left as the corpus had it.
- **Sort keys instead of a Comparable value type.** ngram_counts and word_frequency drop Ruby's
  `Gram`/`Rank` classes (`include Comparable`, `<=>`) for a Tuple key `[-c, k]`
  (ngram_counts.sake:23, word_frequency.sake:31); rake_keywords keeps `Keyword` with `<=>`. A Ruby
  programmer would first notice the missing class in those two.
- **`&:sym` blocks.** Every `map(&:region)`, `group_by(&:ip)`, `sum(&:units)` becomes a block with
  the accessor spelled out (`{ |s| Sale.get_region(s) }`, csv_pivot.sake:84-98).
- **Accessors with the type name.** `r.status` is `Request.get_status(r)`; inside a class the
  same field is `@status` only for the first parameter. Programs that are mostly top-level
  scripts over records (access_log_urls, csv_pivot, sentiment_lexicon) are the ones that grow
  most against Ruby.
- **`Hash[...]`, `Array[...]`, `Set[...]`** for Ruby's `{}`/`[]` literals, and `nil == x` checks for
  `x.nil?`; `&.` (inverted_index.rb:84) is written as two early `return false unless` steps
  (inverted_index.sake:69-78).
