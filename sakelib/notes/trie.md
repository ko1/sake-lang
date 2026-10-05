# trie

`sakelib/trie.sake`: a prefix tree of String keys with values: insert, lookup, prefix search, longest
prefix, delete with pruning. The reference is `test/sakelib/ref/trie.rb` (plain Ruby, in the style of the
rambling-trie / triez gems). 14 operations; the test prints 51 lines, identical to `trie.rb`, including
non-ASCII keys and the empty key.

## API

| Ruby (ref) | Sake | |
|---|---|---|
| `Trie.new` | `Trie.new` | same |
| `t.insert(word, value = true)`, `t[word] = v` | `Trie.insert(t, word, value = true)`, `t[word] = v` | same |
| `t[word]`, `t.include?(word)`, `t.starts_with?(prefix)` | `t[word]`, `Trie.include?(t, w)`, `Trie.starts_with?(t, p)` | same |
| `t.prefix_search(prefix)` | same | same (keys in character order) |
| `t.longest_prefix(s)` | same | same (nil when no key is a prefix) |
| `t.delete(word)` | same | same (returns the value; prunes empty branches) |
| `t.size`, `empty?`, `keys`, `to_a`, `each { \|k, v\| }`, `node_count` | same | same |
| `Trie::Node` | `TrieNode` | differs: no nested names |

## What differs from Ruby, and why

- The node type is `TrieNode` (no nested names) with `attr_accessor` fields, since `Trie` writes them
  (`TrieNode.set_terminal(n, true)`). Ruby's ref uses a Struct, so the same.
- `find` and `collect` are public (Sake has no private functions; only private fields).
- A non-String key raises `NoMatchingPatternError` (`word => String`); the reference does the same.

## Friction

1. `def []=(t, word, value) = insert(t, word, value)` → Prism: `invalid method name; a setter method
   cannot be defined in an endless method definition` (Ruby's rule too) → a `def ... end`.
2. `kids[c] ||= TrieNode.new` inside a reduce block → I wrote `next kid if kid` / `kids[c] = TrieNode.new`
   so the block's value is a TrieNode, not `nil | TrieNode`. (`||=` on an index may also have worked; I did
   not try it, to avoid a nil report.)
3. `@x` reads the first parameter's field only, so the recursive helpers (`collect(node, prefix, out)`)
   take the node first and use `TrieNode.children(node)`; in Ruby they are private methods on the trie.
4. Nothing else: the checker passed `--strict=2` on the first run.

## Language features used

- `include Indexable` with `[]` / `[]=`: `t["zebra"] = 100` and `t[w]` as in Ruby: helped.
- An expression default that makes a Struct value: `private attr_reader root = TrieNode.new`, evaluated per
  `Trie.new`: helped (Ruby's `@root = Node.new(...)` in initialize).
- `attr_accessor children = Hash[], value = nil, terminal = false`; optional parameter `value = true`.
- `return nil unless nxt` inside a block (returns from the function).

## Checker findings before the test passed

- `--strict=1` and `--strict=2`: none (after the setter syntax error).

## Types

- `TrieNode.value: true|false | Integer | nil`: the test stores Integers in one trie and `true` (the
  default) in another; nil after delete. A field has one type for all tries. Nothing reads the value as
  a number, so no report.
- `TrieNode.children: Hash[String => TrieNode]`, `Trie.root: TrieNode`.
- partial: `TrieNode.children` gets `nil | TrieNode` in `longest_prefix` and `find` (the local is
  reassigned from a Hash lookup and checked on the next line, which the inference sees as a union at the
  call); the `=> String` check. No unknowns.
