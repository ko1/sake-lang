# Change request: longer employee numbers

The company has grown past 999 employees. From now on an employee `ID` is `E` followed by 3 to 6
digits, and it stands for the employee number given by those digits: `E042`, `E0042` and `E00042`
are all employee 42.

- In both `EMP` and `SHIFT`, an `ID` that is not `E` and 3-6 digits is `bad id`.
- Two ids with the same number are the same employee: an `EMP` for a number that already exists is
  `duplicate employee ID`, and a `SHIFT` may name its employee with any spelling of the number.
  Error messages show the `ID` as written on the failing line.
- The table is ordered by employee number, and its `id` column shows `E` followed by the number
  with at least 3 digits (zero-padded): `E042`, `E999`, `E1000`.

## Example 1

Input:

```
EMP E1000 Ana 20.00
EMP E999 Ben 10.00
EMP E0042 Cy 12.00
SHIFT E042 2026-03-02 09:00 10:00
SHIFT E01000 2026-03-02 09:00 11:00
```

Output:

```
id   name        regular overtime        pay
E042 Cy             1:00     0:00      12.00
E999 Ben            0:00     0:00       0.00
E1000 Ana            2:00     0:00      40.00
     total          3:00     0:00      52.00
```

## Example 2

Input:

```
EMP E007 Dee 15.00
EMP E0007 Eve 15.00
EMP E1234567 Fay 15.00
SHIFT E7 2026-03-02 09:00 10:00
SHIFT E000007 2026-03-02 09:00 10:00
```

Output:

```
line 2: error: duplicate employee E0007
line 3: error: bad id
line 4: error: bad id
id   name        regular overtime        pay
E007 Dee            1:00     0:00      15.00
     total          1:00     0:00      15.00
```
