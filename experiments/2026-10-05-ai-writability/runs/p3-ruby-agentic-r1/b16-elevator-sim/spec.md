# Elevator simulation

Simulate one elevator serving timed requests and report each passenger's wait and ride times.

## Input

The first line is `N D C`: the number of floors N (2 to 50, floors are 1..N), the door time D
(0 to 5), and the capacity C (1 to 20). If it is not exactly three such integers, print
`invalid header` and nothing else. Every number in the input is written with digits only.

Each later line is a request `T F G`: at time T (0 to 1000) a passenger appears on floor F wanting
floor G. A request is invalid if it is not exactly three integers, a floor is outside 1..N, F equals
G, T is over 1000, or T is smaller than the T of the previous valid request. Print
`line K: invalid request` for each invalid line (K is the 1-based line number, the header being line
1), in input order, before anything else, and ignore it. Blank lines are skipped. Valid requests are
the passengers P1, P2, ... in input order. If there are none, print `no passengers` and stop.

## Simulation

Time is an integer. The elevator starts at floor 1 at time 0, with direction `idle`. Repeat until
every passenger has been dropped off, at the current floor f and time t:

1. Requests with T <= t start waiting.
2. Riders whose destination is f get off (drop-offs).
3. Targets are the riders' destinations and the waiting passengers' floors. Direction `up` stays
   `up` if a target is above f, else becomes `down` if one is below f, else `idle`; `down` likewise
   with the sides swapped. If the direction is now `idle` and there are targets, go toward the
   nearest one (ties: the lower floor); if it is f itself, take the direction of the lowest-numbered
   passenger waiting at f.
4. Waiting passengers at f whose own direction (toward G) equals the elevator's get on, lowest
   number first, while fewer than C ride.
5. If anyone got off or on at this step, t increases by D and the step repeats at the same floor.
   Otherwise the elevator moves one floor in its direction (or stays if `idle`) and t increases by 1.

Print each drop-off and pick-up as it happens, drop-offs first, each group by passenger number:
`t=T floor F drop Pi` or `t=T floor F pick Pi`.

Then print `Pi wait W ride R` for each passenger in number order (W = pick-up time − T,
R = drop-off time − pick-up time), then `average wait %.2f ride %.2f` (means over all passengers),
then `done at t=X` with X the last drop-off time.

At most 100 request lines.

## Example 1

Input:
```
6 1 2
0 3 6
2 1 4
2 5 2
9 6 1
```

Output:
```
t=2 floor 3 pick P1
t=6 floor 6 drop P1
t=8 floor 5 pick P3
t=12 floor 2 drop P3
t=14 floor 1 pick P2
t=18 floor 4 drop P2
t=21 floor 6 pick P4
t=27 floor 1 drop P4
P1 wait 2 ride 4
P2 wait 12 ride 4
P3 wait 6 ride 4
P4 wait 12 ride 6
average wait 8.00 ride 4.50
done at t=27
```

## Example 2

Input:
```
5 0 1
3 2 4
3 2 5
1 1 1
3 9 2
hello
2 3 1
7 4 3
```

Output:
```
line 4: invalid request
line 5: invalid request
line 6: invalid request
line 7: invalid request
t=4 floor 2 pick P1
t=6 floor 4 drop P1
t=8 floor 2 pick P2
t=11 floor 5 drop P2
t=12 floor 4 pick P3
t=13 floor 3 drop P3
P1 wait 1 ride 2
P2 wait 5 ride 3
P3 wait 5 ride 1
average wait 3.67 ride 2.00
done at t=13
```
