# thor (Thor, Thor::Option, Thor::Options, Thor::Command, Thor::Shell::Basic.print_table)

`require "thor"` → `sakelib/thor.sake`. Test: `test/sakelib/thor.{sake,rb}` (identical output); the Ruby side uses the
real gem (thor 1.5.0 is installed): a `Repo < Thor` class with six commands, run with `Repo.start(argv, debug: true)`
over 46 scripted argv Arrays (every option type, `--no-`/`--skip-`, `-sv`, `-t2`, `--k=v`, `--`, a prefix, an
ambiguous prefix, a mapped alias, `help`, `help CMD`, `tree`, and each error). The help text and the error messages
are the gem's, byte for byte, including the truncated `help` description line at 80 columns.

## The shape

Thor finds a command's method by name (`instance.__send__(name, *args)`) and reads its arity; Sake has neither
dispatch by name nor reflection. So:

- **The command table is data.** `Thor.app("repo")` makes a `ThorApp`; the gem's class-level DSL lines are
  functions on it, in the same order as in a Thor class: `Thor.desc(app, "greet NAME", "Say hello")`,
  `Thor.long_desc(app, ...)`, `Thor.method_option(app, :shout, type: :boolean, aliases: "-s", desc: "...")`, and
  `Thor.command(app, "greet")` in place of `def greet(name)`, which closes the pending lines into a `ThorCommand`
  (name, usage, description, long description, options, hidden, min/max arguments). `Thor.class_option`,
  `Thor.map(app, "ci", :commit)`, `Thor.default_command`, `Thor.package_name` likewise.
- **The CLI is a type that includes `ThorCLI`.** It holds the table in a field `thor` and defines the module's one
  required function, `run(cli, name, args, options)`, whose body is `case name in "greet" then ... in "add" then ...`.
  `Thor.start(cli, argv)` (or `ThorCLI.start`) finds the command, parses the options, counts the arguments, and
  calls `run` through the mixin, which dispatches to the CLI's type. `help` and `tree` are handled before `run`.
- **Arity comes from the usage.** `"greet NAME"` takes one argument, `"config KEY [VALUE]"` one or two,
  `"add FILES..."` any number (also `*FILES`); thor reads `method(name).arity`. The error is thor's
  (`ERROR: "repo greet" was called with arguments ["a", "b"]` / `Usage: "repo greet NAME"`).
- **`options` is a Hash with Symbol keys** (thor: a HashWithIndifferentAccess). Its values are of every option
  type, so a value is read with its type: `Thor.flag?(options, :shout)`, `Thor.integer(options, :times)`,
  `Thor.number`, `Thor.string`, `Thor.array`, `Thor.hash` (each a `=>` assertion on the value; see 書き心地).
- **Errors are one type**, `ThorError` with a `kind` (`:undefined_command`, `:ambiguous_command`, `:invocation`,
  `:malformatted_argument`, `:required_argument_missing`), since exception types have no hierarchy. `start` prints
  the message to stderr as thor's `shell.error` does and gives nil, exits 1 with `exit_on_failure: true`
  (thor's `exit_on_failure?`), or raises with `debug: true` (thor's `config[:debug]`).

## API

| Ruby (thor 1.5) | Sake | |
|---|---|---|
| `class Cli < Thor`, `def self.basename` | `app = Thor.app("basename")`; `class Cli` with `attr_reader thor` and `include ThorCLI` | differs (above) |
| `desc "usage", "desc", hide: false` | `Thor.desc(app, usage, desc, hide: false)` | same |
| `long_desc "text", wrap: true` | `Thor.long_desc(app, text, wrap: true)` | same (wrapped to THOR_COLUMNS or 80, paragraphs at blank lines) |
| `method_option :n, type:, desc:, default:, required:, aliases:, banner:, enum:, hide:` / `option` | `Thor.method_option(app, :n, ...)` / `Thor.option` | same keywords; `aliases:` a String or an Array; `enum:` an Array |
| `class_option :n, ...` | `Thor.class_option(app, :n, ...)` | same |
| `def name(args)` | `Thor.command(app, "name")` | differs: closes the pending desc/options; arity from the usage |
| `map "ci" => :commit`, `map [a, b] => :x` | `Thor.map(app, "ci", :commit)`, `Thor.map(app, String[a, b], :x)` | same |
| `default_command :name`, `package_name "X"` | `Thor.default_command(app, "name")`, `Thor.package_name(app, "X")` | same |
| `Cli.start(argv, debug: true)` | `Thor.start(cli, argv, debug: true, exit_on_failure: false)` | same; `exit_on_failure?` is a keyword |
| `options[:x]` / `options["x"]` | `options[:x]`; `Thor.flag?/integer/number/string/array/hash(options, :x)` | Symbol keys only; typed readers added |
| `help`, `help CMD`, `-h`/`-?`/`--help`/`-D` | same, built in (`ThorCLI.help(cli, name = nil)`) | same text: "Commands:" table sorted, truncated at the width; "Options:" with `# Default:` and `# Possible values:`; "Description:" |
| `tree` (1.5) | same, built in (`ThorCLI.tree(cli)`) | same icons; the root line is the basename (thor: the class's namespace, `repo` for `Repo`) |
| option parsing: `--k v`, `--k=v`, `-k v`, `-k5`, `-ab`, `--no-k`/`--skip-k`, `--k true/false`, arrays and hashes taking the following values, `--`, unknown switches kept as arguments, a unique prefix of a command, ambiguous prefixes | `ThorOptionParser` (thor's `Options#parse` step by step) | same, including the quirks (`--tags=one -- c.rb` gives `["one", "c.rb"]`; `-t-5` loses the sign) |
| error messages: `Could not find command "x".`, `Ambiguous command c matches [...]`, `No value provided for required options '--m'`, `No value provided for option '--m'`, `Expected numeric value for '--t'; got "abc"`, `Expected '--level' to be one of 1, 2, 3; got 9`, `You can't specify 'k' more than once ...` | `ThorError` with the same message | same; "Did you mean?" suggestions missing |
| `ThorOption.usage`, `switch_name`, `human_name`, `aliases_for_usage`, `show_default?`, `print_default`, `enum_to_s`; `ThorCommand.formatted_usage`, `hidden?` | same names on the Struct types | same |
| `Thor::Shell::Basic#print_table(rows, indent:, truncate:)`, `print_wrapped` | `Thor.table(rows, indent, truncate)`, `Thor.wrapped(text, indent)` → String | same layout |
| subcommands (`subcommand`, `register`), `Thor::Group`, `invoke`, `argument` (declared positionals), `method_options` (plural), `no_commands`, `check_unknown_options!`, `stop_on_unknown_option!`, `disable_required_check!`, `exclusive`/`at_least_one`, `lazy_default:`, `group:`, `repeatable:`, `namespace`, `$thor_runner`, Array usages | — | missing |
| `Thor::Actions` (files, templates, `run`), `Thor::Shell` (`ask`, `yes?`, `say` with colours, `set_color`), `Thor::Runner` | — | missing |

10 DSL functions, 4 runners (`start`, `dispatch`, `help`, `tree`), 6 option readers, 16 operations on the two
Struct types, the parser (23 operations, internal), 8 text builders. The test runs 46 argv Arrays.

## できたこと / できなかったこと

- **Done.** Everything a README-sized Thor class uses: desc/long_desc/method_option/class_option/map, five option
  types with defaults, required, enum, aliases, banners, hidden options and commands, thor's parsing algorithm
  with its exact precedences, its help and tree text, its error messages. The port of `Options#parse` is a
  line-for-line transcription of the gem into a Struct type whose fields are thor's instance variables
  (`@pile`, `@extra`, `@assigns`, `@switches`, `@shorts`, `@parsing_options`, `@is_treated_as_value`).
- **Changed, by rule.** `def greet(name)` → `Thor.command(app, "greet")` plus a branch in `run`: no method found by
  name. The arity from the usage instead of the method. `options` typed readers instead of `options[:times]`
  used directly (below). One exception type with a kind. `basename` given to `Thor.app` ($PROGRAM_NAME is not a
  file the test can control). `tree` prints the basename where thor prints the class's namespace (no class name
  of a value).
- **Not done.** Subcommands (a `Thor` class per subcommand, found by `const_get`): would be a `ThorApp` per
  subcommand held in the parent's table with a `run` that forwards; the dispatch and help plumbing is the gem's
  biggest piece and was out of budget. `Thor::Actions`/`Shell` (file generators, prompts): a different library.
  DidYouMean suggestions on an unknown command (the gem appends `Did you mean?  commit` through `DidYouMean::
  SpellChecker`): no counterpart; the test uses `push`, which the gem does not correct either. `lazy_default`,
  `group:`, `repeatable:`, exclusive/at-least-one relations: left out, each a few lines in the parser.
- **A design point to think about.** `run(cli, name, args, options)` must have an `else` branch (a String is
  open); `--strict` does not check that every registered command has a branch, and a missing one is a runtime
  `NoMatchingPatternError` (or the user's `raise`). Registration and dispatch are two lists that must agree, which
  Ruby's `def` gave for free. Sake could close it if `Thor.command` took the branch as data, but a block cannot be
  stored, so the only shape left is the `case`.

## 書き心地

- **The options Hash.** First write in the test CLI, as in the Ruby twin: `Integer.times(options[:times]) { puts g }` →
  `u1.sake:8:7: error: Integer.times: argument 1 must be Integer, but can be Float | nil | String [mixed]` /
  `hint: the value has several types here; make each of them fit` / `hint: reached by the call at line 17 →
  thor.sake:262 → thor.sake:746 → thor.sake:779`. True: the parser puts every option's value into one Hash, so
  each read is the union of all option types, and Ruby's `options[:times].times` is exactly the line a Sake user
  cannot write. Written instead: `Thor.integer(options, :times)`, whose body is `v = options[k]; v = default if
  v == nil; v => Integer; v`, so the type fact is asserted where the value is read; `Thor.flag?` is `options[k] ==
  true`. The report is labelled `[mixed]` because the Hash lives in a field of `ThorOptionParser`: the heuristic
  for "a field shared by unrelated instances" fired on a Hash that genuinely holds mixed values, and the hint
  ("make each of them fit") is apt though the label is not. The alternative, one Hash per option type, would
  not read as thor.
- **The required field.** A type that includes `ThorCLI` without a `thor` field →
  `error: `include ThorCLI` in Cli: ThorCLI.dispatch needs `thor`, which Cli does not define (used at line 757)`
  (once per function that reads it). This is the contract of the mixin stated by the checker, and it is why
  `thor` is not declared in the module: an includer's `attr_reader thor` is the definition.
- **Keywords as the gem's option Hash.** `Thor.method_option(app, :shout, typ: :boolean)` →
  `error: Thor.method_option has no keyword parameter `typ`` / `hint: did you mean `type:`?`. Thor itself ignores
  an unknown option key. Six DSL functions repeat the same nine keywords, because `**opts` cannot be passed on
  (`csv_bug_double_splat_pass_on.sake`); `build_option` takes them positionally.
- **Transcribing the parser.** Ruby's `case shifted when SHORT_SQ_RE ... when EQ_RE` with `$1`/`$2` became
  `m = String.match(shifted, short_sq_re); if m ... MatchData.[](m, 1) || ""`: four `if m` blocks where Ruby has one
  `case`, and `|| ""` on every group (a group may be nil). `peek`/`shift`/`unshift` with their flag side effects
  are the same five functions. `shifted => String` after `Array.shift(@pile)` was written defensively and turned
  out unnecessary at level 2 (the nil of `shift` is exempt); kept, as the fact is true inside the `while peek`.
- **Where Sake helped.** `case type in :boolean ... in :hash` over the five option Symbols needs no `else`
  (Symbol literals are tracked as values); `ThorOption.initialize` turns `ThorOption.new(name, type: :boolean)`
  into the defaults (`@type = :string if @type == nil`) and rejects a boolean required option as thor does; the
  typed Arrays `ThorCommand[]`, `ThorOption[]`, `String[]` for `pile`/`extra` meant the parser never had to ask
  what it held. The whole library and the 46-case test ran under `--strict` on the first run and matched the gem
  on the first diff; the only earlier edit was removing an `&:to_s` written by Ruby habit before running.
- **What reads worse than Ruby.** The user's `run` is a dispatch table by hand, and `Thor.command(app, "greet")`
  after the `desc` lines is a line Ruby does not need. The DSL on an explicit `app` reads fine
  (`Thor.desc(app, ...)` is `desc ...` with its subject named), and the test program is as long as the Ruby one.

## Built-ins requested

- A way for a checker to relate a String literal set to a `case`: registered command names are Strings made at
  run time, so `run`'s `case name` cannot be checked for completeness. (A design question rather than a built-in.)
- `**opts` pass-through, to write the nine option keywords once.
- `Kernel.PROGRAM_NAME` is there; `File.basename(PROGRAM_NAME)` is what thor's default `basename` would be, and
  a test cannot control it, so `Thor.app` takes the name.
