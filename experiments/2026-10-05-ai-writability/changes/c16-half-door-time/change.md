# Change: door times in half units

The door time D in the header may now have a half: it is written as digits, optionally followed by
`.5` (`0.5`, `1.5`, `00.5`), with a value from 0 to 5. Any other form (`.5`, `1.0`, `2.25`, `5.5`)
makes the header invalid. N, C and the request numbers are still digits only.

Because each stop with drop-offs or pick-ups now adds D, times, waits and rides may be halves.
Wherever the output shows a time, a wait or a ride (`t=T` in pick/drop lines, `wait W`, `ride R`,
`done at t=X`), a whole value is written as before, and a value with a half is written as its whole
part followed by `.5` (`6.5`, `0.5`). The averages keep their two-decimal format.

## Example 1

Input:
```
6 1.5 2
0 3 6
2 1 4
2 5 2
9 6 1
```

Output:
```
t=2 floor 3 pick P1
t=6.5 floor 6 drop P1
t=9 floor 5 pick P3
t=13.5 floor 2 drop P3
t=16 floor 1 pick P2
t=20.5 floor 4 drop P2
t=24 floor 6 pick P4
t=30.5 floor 1 drop P4
P1 wait 2 ride 4.5
P2 wait 14 ride 4.5
P3 wait 7 ride 4.5
P4 wait 15 ride 6.5
average wait 9.50 ride 5.00
done at t=30.5
```

## Example 2

Input:
```
4 0.5 2
0 2 4
1 3 1
1 1 2
```

Output:
```
t=1 floor 2 pick P1
t=3.5 floor 4 drop P1
t=5 floor 3 pick P2
t=7.5 floor 1 drop P2
t=7.5 floor 1 pick P3
t=9 floor 2 drop P3
P1 wait 1 ride 2.5
P2 wait 4 ride 2.5
P3 wait 6.5 ride 1.5
average wait 3.83 ride 2.17
done at t=9
```
