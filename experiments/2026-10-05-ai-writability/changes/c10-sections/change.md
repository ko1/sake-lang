# Change request: recipe sections

Recipes now group ingredients into sections (dough, filling, ...). From now on an ingredient line
may end with a section tag: a last field that starts with `@`.

- A valid tag is `@` followed by 1-12 lowercase letters `a-z`; the section's name is the part after
  `@`. A last field that starts with `@` but is not a valid tag fails with `bad section`, checked
  after `unknown unit U` and before `missing name`. The tag is not part of the ingredient's name.
- Amounts are combined only within the same section: the same name and unit group in two
  sections (or in a section and outside any section) gives separate lines.
- Output: after the `serves` line, first the ingredients without a section, then each section
  in the order in which it first appeared, as a line `[NAME]` followed by its ingredients. Within
  each part, the lines are in first-seen order as before.

## Example 1

Input:

```
SERVES 2 -> 4
1 cup sugar @syrup
200 g flour @dough
1 - egg
1/2 cup sugar @dough
1 tbsp sugar @syrup
```

Output:

```
serves 4 (x 2)
2 egg
[syrup]
34 tbsp sugar
[dough]
400 g flour
1 cup sugar
```

## Example 2

Input:

```
SERVES 1 -> 1
1 g salt @Top
1 g salt @
2 tsp @top
1 g sea salt @top @top
```

Output:

```
serves 1 (x 1)
line 2: error: bad section
line 3: error: bad section
line 4: error: missing name
[top]
1 g sea salt @top
```
