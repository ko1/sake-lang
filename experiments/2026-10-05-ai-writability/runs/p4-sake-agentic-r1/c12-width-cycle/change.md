# Change: a width for each paragraph

The first line may now hold several widths, one per paragraph.

## Input

The first line holds one or more widths separated by spaces or tabs (leading and trailing ones
ignored). Each width must consist of digits only, with a value from 2 to 80. If the line has no
width, any width is invalid, or the input is empty, print exactly `invalid width` and nothing else.

## Layout

Paragraph k (counting from 1) is laid out with width W_k: the widths are used in the
order given, starting again from the first when they run out. Word breaking, filling and
justification of a paragraph use its own W_k.

## Output

The frame width F is the largest width given on the first line. The borders have F `-`
characters, every text line is padded with spaces on the right to F characters, and the empty
framed line between paragraphs has F spaces. The final summary line is unchanged.

## Example 1

Input:
```
24 12
The quick brown fox jumps over the lazy dog. It was
not amused.

Short one, but not that short.

Back to the wide width again.
```

Output:
```
+------------------------+
|The   quick   brown  fox|
|jumps over the lazy dog.|
|It was not amused.      |
|                        |
|Short   one,            |
|but not that            |
|short.                  |
|                        |
|Back  to  the wide width|
|again.                  |
+------------------------+
paragraphs: 3, lines: 8, words: 25
```

## Example 2

Input:
```
10 3 07

abcdef ghij

abcdefg hi

lorem ipsum dolor

z
```

Output:
```
+----------+
|abcdef    |
|ghij      |
|          |
|ab-       |
|cd-       |
|efg       |
|hi        |
|          |
|lorem     |
|ipsum     |
|dolor     |
|          |
|z         |
+----------+
paragraphs: 4, lines: 10, words: 8
```
