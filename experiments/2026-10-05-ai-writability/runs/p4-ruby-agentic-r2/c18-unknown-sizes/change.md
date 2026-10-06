# Change: files of unknown size

Some scanners cannot read every file's size. From now on, the SIZE token of a file line may also be
exactly `?`, meaning the file exists but its size is unknown. Any other non-numeric SIZE is still
malformed (`??`, `?5`, `-?`). Duplicate and conflict checks treat such a file like any other file.

- The **known size** of a file of unknown size is 0; a directory's known size is the sum of the known
  sizes of all files below it. Ordering of entries (size descending, then name) and the threshold
  comparison use known sizes, except that a file of unknown size is never counted among the smaller
  entries: it is always printed.
- A node is **incomplete** if it is a file of unknown size, or a directory with such a file anywhere
  below it (also below depth D).
- The SIZE column of a file of unknown size is `?`. For an incomplete directory (the root included) it
  is the size text of its known size followed by `+`, e.g. `8.3K+`. A `(K smaller)` line gets the `+`
  when any of its entries is incomplete. The column is still right-justified to 6 characters.

Everything else stays as in the spec.

## Example 1

Input:

    depth 2 threshold 1000
    4000 src/main.c
    ? src/util/strings.c
    1500 src/util/hash.c
    700 src/util/log.c
    300 README
    ? LICENSE
    2048 docs/guide.txt

Output:

     8.3K+  .
     6.1K+    src/
      3.9K      main.c
     2.1K+      util/
      2.0K    docs/
      2.0K      guide.txt
         ?    LICENSE
      300B    (1 smaller)

## Example 2

Input:

    depth 1 threshold 100
    ? a/x
    40 a/y
    2000 b
    30 c
    ? d
    7 d/q
    ? e f
    ?? g

Output:

    line 7: conflict d/q
    line 8: malformed
    line 9: malformed
     2.0K+  .
      2.0K    b
         ?    d
      70B+    (2 smaller)
