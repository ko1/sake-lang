# ruby-progressbar

`require "ruby_progressbar"` → `sakelib/ruby_progressbar.sake`, after the ruby-progressbar gem (1.13.0,
installed: the twin `test/sakelib/ruby_progressbar.rb` runs the gem itself). Test:
`test/sakelib/ruby_progressbar.{sake,rb}`, 58 identical lines (every molecule, a fixed clock, an
unknown total, the limits, the warnings, the exact bytes a terminal would receive). 26 operations plus
the readers of the gem's options.

Ruby's `ProgressBar.create(opts)` returns a `ProgressBar::Base`; here `ProgressBar` is the type and
`ProgressBar.create` takes the gem's options as keywords. `ProgressBar::InvalidProgressError` is
`InvalidProgressError` (no nested names).

## API

| Ruby (ruby-progressbar) | Sake | |
|---|---|---|
| `ProgressBar.create(total:, title:, format:, length:, progress_mark:, remainder_mark:, output:, throttle_rate:, starting_at:, autostart:, autofinish:, unknown_progress_animation_steps:)` | `ProgressBar.create(...)` with the same keywords | same |
| `projector: {type: "smoothed", strength: 0.1}` | `projector_strength: 0.1` | differs: one projector, its strength |
| `time: ProgressBar::Time.new(clock)` (a time source) | `clock: Time.at(...)`, `ProgressBar.set_clock(bar, t)` | differs: a fixed Time instead of an object with `now`; nil = `Time.now` |
| `output: io` (tty or not), `output: ProgressBar::Outputs::Null` | `output: io` (IO or StringIO), `output: nil` | differs: always the TTY behaviour (below) |
| `bar.increment`, `decrement`, `finish`, `reset`, `pause`, `stop`, `resume`, `start(at:)` | `ProgressBar.increment(bar)`, ... | same (`start` needs `at:`) |
| `bar.progress = n`, `bar.total = n` | `ProgressBar.set_progress(bar, n)`, `set_total` | differs: name (no setters); raises `InvalidProgressError` as the gem |
| `bar.title = s`, `format = s`, `progress_mark = s`, `remainder_mark = s` | `ProgressBar.set_title(bar, s)`, ... | differs: name; each redraws, as the gem |
| `bar.progress`, `total`, `title`, `format`, `length` | `ProgressBar.progress(bar)`, ... | same |
| `bar.to_s`, `bar.to_s(new_format)` | `ProgressBar.to_s(bar)`, `to_s(bar, fmt)` | same (the new format stays) |
| `%t %T %c %C %u %p %P %j %J %a %e %E %f %l %B %b %W %w %i %r %R %%` | the same molecules | same text |
| `bar.finished?`, `started?`, `stopped?`, `paused?` | same | differs: true/false (the gem gives a Time or nil for the last three) |
| `bar.log(s)`, `bar.clear`, `bar.refresh` | `ProgressBar.log(bar, s)`, `clear`, `refresh` | same |
| `bar.to_h`, `bar.inspect` | `ProgressBar.to_h(bar)`, `p bar` | same keys; `started?`/`stopped?` true/false |
| `rate_scale: ->(r) { r / 1024 }` | — | missing: a stored lambda |
| `Outputs::NonTty` (the piecewise output when not a tty) | — | missing: no `tty?`; see below |
| terminal width (`io/console` winsize, `stty`, `tput`) | — | missing: `length:`, else `ENV["RUBY_PROGRESS_BAR_LENGTH"]`, else 80 |
| `smoothing:`, `running_average_rate:` (deprecated), `ProgressBar::Refinements::Enumerator#with_progressbar` | — | missing (deprecated; a refinement) |

## できたこと / できなかったこと

- Ported: the whole rendering (the formatter's two passes: the plain molecules first, then the bar
  molecules get the width that is left, escape codes not counted), the timer (start/stop/pause/resume
  and the elapsed time frozen while paused), the ETA from the smoothed projection, the rate, the wall
  clock, the unknown-total animation, the limits and their messages, the two warnings on stderr, and
  the terminal protocol: a redraw per update with `\r`, `\n` once stopped, a blank line before the first
  draw, `log` clearing the line and redrawing.
- **Output side.** The gem chooses by `output.tty?`: on a TTY it honours `format:` and redraws; on a pipe
  it ignores `format:`, prints the default `%t: |%b|` as it grows, and `format=` is a no-op. Sake has no
  `IO.tty?`, so the port always behaves as the TTY output; a nil output writes nothing (the gem's
  `Outputs::Null`, which also drops `format:`), and `to_s` renders in any case. The test runs the gem
  with a StringIO that answers `tty?` with true, so both sides show the same bytes; the gem under a
  plain pipe would print `Progress: |====` piecewise, ignoring the format.
- **Time.** The gem takes a time source object (`time:`); Sake cannot pass an object with a `now`
  method, so `clock:` is a Time that the program moves (`set_clock`). The gem's throttle has its own real
  clock; here it reads the same clock, so a fixed clock with the default 0.01 s rate would never redraw
  (the test sets `throttle_rate: 0`).
- `rate_scale` is a lambda stored in the bar: not storable. `%r` shows the raw rate.
- `percentage_completed_with_precision` returns `100.0` / `0.0` (Floats) or a `"%5.2f"` String in the gem;
  here always a String, and `to_h`'s `percentage` converts it with `String.to_f`. One result type per
  function, again (as strscan's notes say).
- The projector is a type in the gem (`Projector.from_type(name)`), one of one; here the two fields it
  needs (`projection`, `starting_position`) live in the bar.

## 書き心地

- First `--strict` run: `ruby_progressbar.sake:129: Arithmetic.*: the operands may be nil ([Integer |
  nil, Integer]) [nil]` at `@progress * 100 / t`, with twelve hint lines naming every field that may be
  nil, StringIO's internals included. The one that mattered: `ProgressBar.progress may be nil (nil is
  stored at line 40, 204, 225)`. Line 204 was `@progress = @total unless unknown?(b)`: a helper that tests
  `@total == nil` does not narrow the field, so the typer saw a nil stored → `t = @total; @progress = t if
  t != nil`. Line 225 was `@progress = @starting_position` in `reset`, and `starting_position` got
  `@progress` in `start`: two fields feeding each other's nil. Broke the cycle by making `start(b, at:)`
  required (the gem's `at:` is optional). Right diagnosis, a long hint.
- In the test, `ProgressBar.set_clock(bar2, ProgressBar.clock(bar2) + step)` → `Arithmetic.+: the operands
  may be nil ([nil | Time, Integer])`: a field read is not narrowed, and the field may hold nil for other
  bars. Kept the clock in a local, `clock2 += step; ProgressBar.set_clock(bar2, clock2)`, which is also
  what the Ruby twin does with its fake clock (`clock2.now += step`).
- `(IO|StringIO).print(o, s)` → `error: \`IO\` is not a type; \`(...)\` lists types (Struct types or built-in
  types)`, although `in IO` matches. Wrote a `case o in IO ... in StringIO ... in nil` in `write_out`.
  Repro: `ruby_progressbar_bug_io_in_type_list.sake`.
- A field named `format` (the gem's name) shadows `Kernel.format` inside the class: every `format("%02d:
  ...")` had to be `Kernel.format(...)`. The checker would have caught a bare one (the reader takes one
  argument), but the shadowing is a trap to know.
- The gem's `MOLECULES` table maps `%t` to `[:title_component, :title]` and calls them with `__send__`.
  Here it is `case key in "%t" | "%T" then @title in "%c" then ... else raise KeyError`, one line per
  molecule; it reads better than the table, and the unknown-molecule case is explicit. The `else` is
  needed because `key` is an open String (exhaustiveness is level 3 for those).
- `create` with 14 keyword parameters forwarded one by one to `ProgressBar.new(total: total, ...)` is the
  dull part: the gem passes one `options` Hash through five constructors. The reward: `ProgressBar.create(total:
  4, lenght: 40)` → `error: ProgressBar.create has no keyword parameter \`lenght\`` / `hint: did you mean
  \`length:\`?`; the gem silently uses 80 columns.
- What read as well as Ruby: `loop do ... break v end`; `hours, rest = Integer.divmod(seconds, 3600)`;
  `String.[](frame * n, 0, len) || ""` for the animation window; `@projection = ... ` arithmetic as is.
- After the two nil fixes, the output matched the gem byte for byte on the first comparison, including
  the `\r`-separated terminal stream and the ETA arithmetic (`00:00:24` from a projection of 0.9).

## Built-ins requested

- `IO.tty?(io)`: the gem's output choice, and HighLine's, hinge on it; without it a library cannot tell a
  terminal from a pipe.
- `IO.winsize(io)` (or `IO.console_size`): the default bar width is the terminal's.
- `IO` accepted in the type list `(IO|StringIO).print(...)`: three stream operations each needed a
  two-branch `case` (also in highline.sake).
- `Kernel.p(*xs)` with several arguments (as in colorize's notes).
