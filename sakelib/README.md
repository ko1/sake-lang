# sakelib: Sake's library

Ports of Ruby's standard library. `require "json"` finds `sakelib/json.sake` when there is no
`json.sake` next to the requiring file. Names follow Ruby's: `JSON.parse(s)`, `Base64.encode64(s)`.
A Ruby instance method becomes an operation with the subject first: `StringScanner.scan(ss, /\w+/)`.

Tests: `test/sakelib/NAME.sake` (run with `--strict`) must print what `test/sakelib/NAME.rb`, the same
program with Ruby's library, prints (`ruby -Ilib test/test_sakelib.rb`).

Each library's notes (what differs from Ruby and why, what is missing): `sakelib/notes/NAME.md`.
