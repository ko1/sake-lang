# Change: tied preferences on a ballot

A rank is now one or more names separated by `=` (spaces around names ignored; candidate names never
contain `=`): `Ana = Ben > Cal` ranks Ana and Ben equal first.

## Validation

Ranks are checked left to right, and names within a rank left to right. The ballot is rejected at the
first name that is empty (`empty rank`, also in `Ana= > Ben`), unknown (`unknown candidate NAME`), or
already named earlier on the ballot, same rank included (`duplicate NAME`).

## Counting

Each round a ballot goes to its highest rank holding a continuing candidate, split equally among that
rank's continuing candidates (1/3 each for `A=B=C`). Votes are fractions; majority, elimination, the
order of the round lines and the share use exact values. `active` and `exhausted` count whole ballots.

## Output

Whole votes print as before; others with two decimals, rounded half up (11/8 is `1.38`).

## Example 1

Input:

    Ana Ben Cal
    Ana = Ben > Cal
    Cal
    Ben
    Cal > Ana=Ben
    Ana

Output:

    ballots: 5 valid, 0 rejected
    round 1
      Cal 2 40.0%
      Ana 1.50 30.0%
      Ben 1.50 30.0%
      exhausted 0
      eliminated Ben
    round 2
      Ana 2 50.0%
      Cal 2 50.0%
      exhausted 1
      eliminated Ana
    round 3
      Cal 3 100.0%
      exhausted 2
    winner Cal

## Example 2

Input:

    X Y Z
    X=Y=Z
    X
    Y > Z = X
    Y=W
    Z = Z

Output:

    rejected line 5: unknown candidate W
    rejected line 6: duplicate Z
    ballots: 3 valid, 2 rejected
    round 1
      X 1.33 44.4%
      Y 1.33 44.4%
      Z 0.33 11.1%
      exhausted 0
      eliminated Z
    round 2
      X 1.50 50.0%
      Y 1.50 50.0%
      exhausted 0
      eliminated Y
    round 3
      X 3 100.0%
      exhausted 0
    winner X
