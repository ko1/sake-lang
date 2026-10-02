# NOTES (02-analytics, corpus-v2)

All previously reported problems are gone: Tuples sort, `-x` and `!x` work, `each_cons` windows
destructure, `Array.join(xs)` without a separator works, and `Set.select` now returns an Array
as documented (spec §15, the same as Ruby).

What is still worked around:

- **No nested block parameters.** `|(w, c), i|` (each_with_index over pairs) and `|(a, b), c|`
  (a Hash with Tuple keys) are still static errors:
  `nested destructuring (a, b) is not supported; |a, b| already destructures a Tuple`.
  Programs bind `|pair, i|` and then `w, c = pair` (word_frequency, language_guess,
  vocabulary_growth, ngram_counts, naive_bayes, kwic_concordance, cooccurrence_pmi).
  Repro: `Hash.each(Hash[[1, 2] => 3]) { |(a, b), c| p(a) }`.
- **A one-group `String.scan` result is a 1-Tuple**, read as `m[0]` (hashtag_trends); there is no
  one-element destructuring, so that is fine but slightly noisy.
- **Two-pass "stable" sorts.** The Ruby versions of tf_idf and cooccurrence_pmi sort twice and
  rely on the second sort's tie order. The Sake versions now use one Tuple key, which gives the
  same output here and does not depend on sort stability.

No interpreter bugs were found in this round.
