# Instant-runoff election

## Input (standard input)

Line 1 lists the candidates, separated by spaces (at most 10 distinct names without spaces or
`>`, case-sensitive). Each later line is a ballot: names in order of preference separated by `>`,
spaces around each name ignored. Blank lines (empty or only spaces) are skipped. At most 500 lines.

A ballot is rejected at its first rank, left to right, that is empty (`empty rank`), not a
candidate (`unknown candidate NAME`), or already ranked on it (`duplicate NAME`).

## Counting

Each round, every valid ballot counts for its highest-ranked continuing (not eliminated)
candidate, or is exhausted if it ranks none. `active` is the number of non-exhausted valid ballots.

- If `active` is 0, there is no winner and counting stops.
- If a candidate has count * 2 > active, that candidate wins.
- Otherwise one candidate is eliminated: the one with the fewest votes this round. Among those tied
  for fewest, keep those with the fewest votes in the previous round, then the round before that,
  and so on back to round 1; if several remain, eliminate the one whose name is last in byte order.

## Output

First, for each rejected ballot in input order: `rejected line N: REASON` (line 1 is the
candidate line). Then `ballots: V valid, R rejected`. If line 1 is missing or has no names, print
only `no candidates`.

Each round prints `round K`, then one line per continuing candidate, sorted by votes descending,
then name ascending (byte order): two spaces, the name, the votes, and the share of `active` as a
percentage with one decimal and a `%` sign. The share is rounded half up (12.25% is `12.3%`);
it is `0.0%` when `active` is 0. Then `  exhausted E`. The round ends with `  eliminated NAME`,
or with `winner NAME` or `no winner` (not indented), which ends the output.

## Example 1

Input:

    Ana Ben Cal Dee
    Ana > Ben > Cal
    Ben > Ana
    Cal > Ben > Ana
    Ana
    Dee > Cal > Ben
    Ben > Cal
    Ana > Dee
    Cal > Ana
    Ben > Eve

Output:

    rejected line 10: unknown candidate Eve
    ballots: 8 valid, 1 rejected
    round 1
      Ana 3 37.5%
      Ben 2 25.0%
      Cal 2 25.0%
      Dee 1 12.5%
      exhausted 0
      eliminated Dee
    round 2
      Ana 3 37.5%
      Cal 3 37.5%
      Ben 2 25.0%
      exhausted 0
      eliminated Ben
    round 3
      Ana 4 50.0%
      Cal 4 50.0%
      exhausted 0
      eliminated Cal
    round 4
      Ana 6 100.0%
      exhausted 2
    winner Ana

## Example 2

Input:

    North South West
    West > North
    South
    North > West > South

    North > North
    South > West
    North
     > South
    West
    South > North

Output:

    rejected line 6: duplicate North
    rejected line 9: empty rank
    ballots: 7 valid, 2 rejected
    round 1
      South 3 42.9%
      North 2 28.6%
      West 2 28.6%
      exhausted 0
      eliminated West
    round 2
      North 3 50.0%
      South 3 50.0%
      exhausted 1
      eliminated North
    round 3
      South 4 100.0%
      exhausted 3
    winner South
