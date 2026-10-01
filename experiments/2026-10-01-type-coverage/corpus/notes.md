# Notes

## fizzbuzz
- Runs until success: 1
- Errors: none

## primes
- Runs until success: 1
- Errors: none

## bank
- Runs until success: 1
- Errors: none

## shapes
- Runs until success: 2
- Errors (run 1):
  - `shapes.sake:1:1: error: constant assignment is only supported as `PI = Data.define(...)``
  - `shapes.sake:7:17: error: type `PI` cannot be used as a value` (and same at 8:28)
  - No hint lines.
- Hint told the fix? Partly: the message made clear non-Data constants are unsupported, but did not suggest
  an alternative. Fix: replaced `PI = 3.14...` with a zero-arg function `def pi = 3.14...` (the brief has no
  Math::PI or constant other than Data types).

## words
- Runs until success: 1
- Errors: none

## stats
- Runs until success: 1
- Errors: none

## collatz
- Runs until success: 1
- Errors: none

## inventory
- Runs until success: 1
- Errors: none

## linked_list
- Runs until success: 2
- Errors (run 1, runtime):
  - `linked_list.sake:12: in Node.sum: TypeError: BinaryOp.!=: no implementation for (Node, nil); defined for (Integer, Integer), (Integer, Float), (Float, Integer), (Float, Float), (String, String), (true|false, true|false), (nil, nil)`
  - `  from linked_list.sake:39: in <main>`
  - No hint lines.
- Hint told the fix? Not directly. The brief says `==`/`!=` work only between the same type, which explains it;
  the message lists `(nil, nil)` but does not suggest a nil test. Fix: `while node != nil` -> `while node`
  (truthiness; only nil/false are falsy). Note this was a runtime error, not static, despite the nil-terminated
  `next` field being visible from `Node.new(i, head)` with `head = nil`.

## matrix
- Runs until success: 1
- Errors: none
