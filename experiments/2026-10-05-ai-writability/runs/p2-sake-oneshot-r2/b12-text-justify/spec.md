# Justified text in a frame

Lay out text, fully justified to a given width, inside an ASCII frame.

## Input

The first line holds the width W. After removing leading and trailing spaces it must consist of digits only, with a value from 2 to 80. If it does not (or the input is empty), print exactly `invalid width` and nothing else.

The remaining lines (at most 100, each at most 200 characters, ASCII) are the text. A word is a maximal run of characters other than space and tab. A line with no words is blank. Paragraphs are separated by one or more blank lines; blank lines before the first or after the last paragraph are ignored.

## Layout

Each paragraph is laid out separately:

1. A word longer than W is broken: while it is longer than W, its first W-1 characters followed by `-` become a piece, and the rest continues; the final rest (at most W characters) is the last piece. Pieces are then treated as words.
2. Lines are filled greedily: a word goes on the current line if the line's words joined by single spaces still fit in W; otherwise it starts a new line.
3. Every line except the paragraph's last is justified to exactly W characters by widening the gaps between its words. The extra spaces are shared out evenly; when they do not divide evenly, the leftmost gaps get one more space each. A line with a single word, and the paragraph's last line, keep single spaces and are left-aligned.

## Output

- A top border: `+`, W `-` characters, `+`.
- Each text line as `|`, the line padded with spaces on the right to W characters, `|`.
- Between two paragraphs, one empty framed line: `|`, W spaces, `|`.
- A bottom border like the top one.
- Finally `paragraphs: P, lines: L, words: K`, where L counts the framed text lines (not the separators) and K the words of the input before any breaking.

With no paragraphs, only the two borders and `paragraphs: 0, lines: 0, words: 0` are printed.

## Example 1

Input:
```
24
The quick brown fox jumps over the lazy dog. It was
not amused.


Short one.
```

Output:
```
+------------------------+
|The   quick   brown  fox|
|jumps over the lazy dog.|
|It was not amused.      |
|                        |
|Short one.              |
+------------------------+
paragraphs: 2, lines: 4, words: 15
```

## Example 2

Input:
```
 9 

  supercalifragilistic is   a long word

 
ab cd e
```

Output:
```
+---------+
|supercal-|
|ifragili-|
|stic is a|
|long word|
|         |
|ab cd e  |
+---------+
paragraphs: 2, lines: 5, words: 8
```
