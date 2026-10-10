# sakelib: Sake's library

Ports of Ruby's standard library. `require "json"` finds `sakelib/json.sake` when there is no
`json.sake` next to the requiring file. Names follow Ruby's: `JSON.parse(s)`, `Base64.encode64(s)`.
A Ruby instance method becomes an operation with the subject first: `StringScanner.scan(ss, /\w+/)`.

Tests: `test/sakelib/NAME.sake` (run with `--strict`) must print what `test/sakelib/NAME.rb`, the same
program with Ruby's library, prints (`ruby -Ilib test/test_sakelib.rb`).

Each library's notes (what differs from Ruby and why, what is missing): `sakelib/notes/NAME.md`.

Besides the standard library, ports of well-known gems (2026-10-09): colorize, ruby_progressbar, highline,
active_support_{inflector,core_ext,number_helper}, kramdown (GFM), liquid, rack, rackup, webrick, httparty, redis,
dotenv, money, rubyzip, chronic, i18n, faker, thor, awesome_print, concurrent_ruby, jwt, rspec. Each keeps the
gem's names where Sake can (`ActiveSupport::Inflector.pluralize(s)`, `Redis.get(r, k)`); nested names are Ruby's (`Benchmark::Tms`, `JSON::ParserError`); what it drops and why is in its notes.
Libraries not ported, with the reason: `notes/not-ported.md`.

`minitest.sake` is a test framework for programs written in Sake; Sake's own test suite written in Sake is
`test/sake/*_test.sake` (run by `test/test_sake_suite.rb`).
