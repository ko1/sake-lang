# Disk usage tree

Print a summarized directory tree of files with sizes.

## Input

Line 1 is a header of four whitespace-separated tokens: `depth D threshold T`, where D and T are
non-negative decimal integers. If the header is missing or not of this form, print `bad header` and
nothing else.

Each later line (at most 300) is `SIZE PATH`: two whitespace-separated tokens, SIZE a non-negative
decimal integer (at most 10^13) and PATH a relative path of components separated by `/`, where no
component is empty, `.` or `..`. Whitespace-only lines are ignored. Lines are numbered from 1 (the
header). In order, each line is one of:

- any other form: print `line N: malformed`;
- PATH equals an earlier accepted file: print `line N: duplicate PATH`;
- a proper prefix of PATH (whole components) is an accepted file, or PATH is a directory created by
  earlier lines: print `line N: conflict PATH`;
- otherwise the file is accepted, and its missing parent directories are created.

These messages come before the tree.

## Tree

The root directory is `.` at depth 0; its entries are at depth 1, and so on. A directory's size is
the sum of all files below it. Print a node as one line: `format("%6s  %s%s", SIZE, INDENT, NAME)`,
where INDENT is two spaces per depth level, and NAME is `.` for the root, the component followed by
`/` for a directory, and the component for a file.

Print the root, then recursively for each directory at depth below D: its entries ordered by size
descending, then name ascending in byte order (without the `/`). Entries with size below T are not
printed; if there are any, after the other entries print one line at the entries' depth with their
total size and NAME `(K smaller)`, K being their count. Entries of a directory at depth D are not
printed.

## Sizes

Write size s in bytes as follows. If s < 1024, write `sB`. Otherwise let U be the largest of
K = 1024, M = 1024^2, G = 1024^3 not above s. Rounding means to the nearest integer, halves up.
Let t = s*10/U rounded; if t < 100, write t/10 with one decimal and the unit letter (`2.5M`).
Otherwise let n = s/U rounded, and write n with the unit (`10K`); but if n is 1024 and U is not G,
write `1.0` with the next unit instead (`1.0M`).

## Example 1

Input:

    depth 2 threshold 1000
    4000 src/main.c
    2600 src/util/strings.c
    1500 src/util/hash.c
    700 src/util/log.c
    300 README
    12 LICENSE
    2048 docs/guide.txt

Output:

       11K  .
      8.6K    src/
      4.7K      util/
      3.9K      main.c
      2.0K    docs/
      2.0K      guide.txt
      312B    (2 smaller)

## Example 2

Input:

    depth 2 threshold 0
    1572864 data/a.bin
    1048064 data/b.bin
    1000 notes
    5 x y
    2000 data/a.bin
    7 data/a.bin/extra
    3 /etc/passwd
    10239 notes2

Output:

    line 5: malformed
    line 6: duplicate data/a.bin
    line 7: conflict data/a.bin/extra
    line 8: malformed
      2.5M  .
      2.5M    data/
      1.5M      a.bin
      1.0M      b.bin
       10K    notes2
     1000B    notes
