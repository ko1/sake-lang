# sakelib: Sake's library

Ports of Ruby's standard library, and `prelude.sake`, which every program reads first (it defines `Enum`,
Ruby's Enumerable under a short name). `require "json"` finds `sakelib/json.sake` when there is no
`json.sake` next to the requiring file. Names follow Ruby's: `JSON.parse(s)`, `Base64.encode64(s)`.
A Ruby instance method becomes an operation with the subject first: `StringScanner.scan(ss, /\w+/)`.

Tests: `test/sakelib/NAME.sake` (run with `--strict`) must print what `test/sakelib/NAME.rb`, the same
program with Ruby's library, prints (`ruby -Ilib test/test_sakelib.rb`).

Each library's notes (what differs from Ruby and why, what is missing): `sakelib/notes/NAME.md`.

Besides the standard library, ports of well-known gems (2026-10-09): colorize, ruby_progressbar, highline,
active_support_{inflector,core_ext,number_helper}, kramdown (GFM), liquid, rack, rackup, webrick, httparty, redis,
dotenv, money, rubyzip, chronic, i18n, faker, thor, awesome_print, concurrent_ruby, jwt, rspec. Each keeps the
gem's names where Sake can (`ActiveSupport::Inflector.pluralize(s)`, `Redis.get(r, k)`); nested names are Ruby's (`Benchmark::Tms`, `JSON::ParserError`); what it drops and why is in its notes.
More gems (2026-10-11), each with its test written line by line in parallel with the Ruby one so the two can be
read side by side (<https://ko1.github.io/sake-lang/compare.html>): jmespath, hana (JSON Pointer / Patch), msgpack,
pstore, crass (CSS), useragent, mini_mime, erubi, protocol_hpack (HPACK), simpleidn (punycode / IDNA), websocket,
net_smtp, fugit (cron, durations), rss (RSS 2.0 and Atom), rainbow, addressable (URI, URI templates), public_suffix,
unicode_display_width. mini_mime, public_suffix and unicode_display_width read the installed gem's data files.
Libraries not ported, with the reason: `notes/not-ported.md`.

`minitest.sake` is a test framework for programs written in Sake; Sake's own test suite written in Sake is
`test/sake/*_test.sake` (run by `test/test_sake_suite.rb`).
