# Brief: port part of Ruby's standard library to Sake

Goal (ko1): make Sake usable like Ruby by porting Ruby's standard libraries. You port one group of
libraries into Sake's library directory `sakelib/` of the repo `/home/ko1/app/sake`.

Read first: `sakelib/README.md`, `docs/tutorial.md` (skim), `docs/spec.md` (rules), `docs/builtins.md`
(all built-in operations). Sake is Ruby syntax where each operation names its type (`String.upcase(s)`);
calls on values (`s.upcase`) are rejected. `require "json"` loads `sakelib/json.sake`.
`bin/sake --strict FILE` is the recommended level; `bin/sake --types FILE` shows inferred types.

## What to produce

1. `sakelib/<lib>.sake` for each library of your group. Keep Ruby's names: a Ruby module function
   stays one (`JSON.parse(s)`, `Base64.encode64(s)`); a Ruby class becomes a Sake type
   (`class StringScanner < {reader: [...], accessor: [...]}`) and its instance methods become its
   operations with the instance first (`StringScanner.scan(ss, /\w+/)`). Prefer `reader:` fields;
   make Arrays that are filled later with their element type (`Integer[]`) where you can.
   Cover the commonly used API first (what a typical Ruby program calls), then more.
2. Tests: `test/sakelib/<lib>.sake` (a program exercising the API and printing results) and
   `test/sakelib/<lib>.rb` (the same program using Ruby's real library). The two outputs must be
   identical; `ruby -Ilib test/test_sakelib.rb -n /<lib>/` checks it (the .sake runs with --strict).
   Include edge cases (empty input, errors raised and rescued, unicode where relevant).
3. Notes: `sakelib/notes/<lib>.md`: an API table (Ruby call → Sake call, with "same" / "differs" /
   "missing"), what differs from Ruby and why (Sake's rules), what you could not port and why,
   built-ins you needed but Sake lacks (each with a one-line justification), and friction you hit
   (in the form: what you wrote first → message → what you wrote instead).

## Rules

- Do NOT change `lib/`, `docs/`, `test/test_*.rb`, other groups' files, or anything outside your files
  listed above. If a built-in is missing, write it in Sake inside your library if you reasonably can;
  otherwise record it in your notes as a request (the maintainer adds built-ins afterwards).
- If you find an interpreter or checker bug, keep a minimal repro as `sakelib/notes/<lib>_bug_*.sake`.
- Shell commands need `dangerouslyDisableSandbox: true` (the sandbox fails here with a seccomp error).
- Budget: about 90 minutes. If time runs short, stop adding API and finish the notes.
- When done, reply with under 250 words: what was ported (API count), what is missing, the top
  built-in requests, and anything surprising.
