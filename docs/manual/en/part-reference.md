# Built-in reference

One chapter per built-in type or module, listing **every** operation of that namespace. Section headings are the operation names; aliases share a section (`find, detect`). The first line of each section is the exact signature:

- `Array.first(x, [Integer])`: `x` is a value of the namespace's type (the subject), `[T]` an optional argument, `*T` any number of arguments, `[k: T]` a keyword, ` { }` a required block, and ` [{ }]` an optional block.
- `T[...]`, such as `Integer[*Any]`, is the constructor of an **Array** of T values (a typed Array).

The text of each section says what the operation does and returns, what the arguments mean, when the result is **nil** and at which strictness level the checker reports its unchecked use, which **exceptions** it raises, what the checker rejects statically, whether it changes the subject in place or returns a new value, and how it differs from Ruby's method of the same name. The `# => value` annotations in the examples are real output: `ruby tools/check_reference.rb` runs every example under `--strict=2` and compares, and also checks the signatures and that no operation is missing (an example marked `ruby error` is one confirmed to be rejected or to fail).

The chapters go: Kernel and the exceptions, numbers, strings and regular expressions, sequences and maps, time, input/output and the OS, threads and sockets. The rules of the operators (`+`, `<`, `[]`) are in [Operators and indexing](05-operators.md); the nature of each type's values in [Values and types](03-values.md).
