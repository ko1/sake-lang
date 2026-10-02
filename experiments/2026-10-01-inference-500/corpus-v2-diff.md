## Revision round: corpus → corpus-v2

- programs: 500; changed: 337
- code lines (no blanks or comments): 50181 → 49885 (-0.6%)

| new feature | uses before | uses after | programs after |
|---|---|---|---|
| chain x.T.f | 0 | 18 | 7 |
| _ (previous value) | 0 | 1 | 1 |
| (A|B).f | 0 | 29 | 15 |
| unary -x / +x / ~x | 0 | 167 | 130 |
| !x | 0 | 102 | 74 |
| Tuple compared (== < <=> with [..]) | 0 | 11 | 11 |
| sort_by/min_by/max_by with a Tuple key | 0 | 83 | 74 |
| multiple assignment from a call | 376 | 423 | 233 |

| workaround | before | after |
|---|---|---|
| 0 - x (unary minus) | 115 | 1 |
| x == false (negation) | 130 | 0 |
| format("%0..") sort keys | 173 | 136 |
| x[0] / x[1] right after a split | 21 | 17 |

Detected syntactically (Prism); "Tuple compared" counts only comparisons with a literal `[...]` operand.
