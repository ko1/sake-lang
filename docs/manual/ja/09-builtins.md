# 組み込み操作

以下の表はよく使う操作の案内です。**各操作の詳細（引数・戻り値・nil・例外・例）は第 2 部「組み込みリファレンス」に、型ごとに 1 章ずつあります（[Array](ref/Array.md)、[String](ref/String.md)、[Hash](ref/Hash.md)、[Kernel](ref/Kernel.md)、…）。** 名前は Ruby のコアライブラリに従い、「→」は結果の型です。「ブロック」と記したものはブロックが必須です。

## Kernel

| 操作 | 結果 | 備考 |
|---|---|---|
| `puts(*xs)` | nil | Ruby の `puts` と同じ。Array と Tuple は 1 要素 1 行 |
| `print(*xs)` | nil | 改行なし |
| `p(x)`, `p(x, y)`, `pp(x)` | x · `[x, y]` · x | 各引数を Ruby の `inspect` の形で 1 行ずつ。`p()` は nil |
| `format(fmt, *xs)`, `sprintf` | String | Ruby の format。引数は Integer, Float, String, Symbol, nil, true, false |
| `Integer(x)`, `Float(x)`, `Rational(a, [b])`, `Complex(re, [im])` | 数 | Ruby の厳密な変換。不正な入力は `ArgumentError` |
| `rand`, `rand(n)`, `srand(seed)` | Float、または n 未満の Integer/Float | |
| `sleep(secs)` | Integer | |
| `loop { }` | `break` の値 | `break` までブロックを繰り返す |
| `dup(x)` | x の複製 | Ruby の `obj.dup`。`dup` を定義した型はそれを使う |
| `gets` | String か nil | 標準入力の 1 行 |
| `exit(status)` | | Integer、または true で 0 / false で 1（既定 0）。`ensure` は走る。その後のコードには到達しない |
| `warn(x, ...)` | nil | エラー出力へ（`puts` と同じ形） |
| `system(cmd)` | true / false / nil | Ruby の `system` |
| `at_exit { }` | nil | プログラムの終わりに走るブロック |
| `ARGV` | Array of String | プログラムの引数。Ruby の定数のように書くが操作（`Kernel.ARGV`）。毎回同じ Array なので `Array.shift(ARGV)` が効く |
| `Kernel.PROGRAM_NAME` | String | 走っているファイルの名前。`ARGV` と違い、裸では書けない（大文字の名前は型） |
| `equal?(a, b)` | true/false | 同一性 |
| `block_given?` | true/false | 今の関数がブロックを受けたか |

`Math::PI`、`Math::E`、`Float::INFINITY`、`Float::NAN`、`Float::EPSILON`、`Float::MAX`、`Float::MIN` は `ARGV` と同じく操作として読みます（`Math.PI`）。Sake に値の定数は無く、他の入れ子の名前もありません。

`Arithmetic.round(x)`、`floor`、`ceil`、`truncate`（省略可能な桁数付き）、`abs`、`to_f`、`to_i`、`zero?` は Ruby の `x.round` と同じくどの実数（Integer, Float, Rational）も取り、結果の型は x に従います（桁なしの round は Integer）。`Float.round` は Float だけを名乗ります。

## Integer / Float

| 操作 | 結果 |
|---|---|
| `+ - * / % **` | Integer（Float なら Float） |
| `< <= > >= == !=` | true/false |
| `Integer.to_s(n, base = 10)`, `to_f`, `abs`, `succ`, `pred` | String, Float, Integer, Integer, Integer |
| `even?`, `odd?`, `zero?` | true/false |
| `times(n) { \|i\| }` · `upto(a, b) { }` · `downto(a, b) { }` · `step` | n · a · a（ブロック） |
| `& \| ^ << >>` | Integer |
| `divmod(a, b)` | `[商, 余り]` の Tuple（Float は `[Integer, Float]`） |
| `gcd`, `lcm`, `pow(a, b, [mod])`, `bit_length`, `sqrt(n)`, `clamp(n, lo, hi)` | Integer |
| `digits` · `chr` · `between?(n, lo, hi)` | Array of Integer · String · true/false |
| `Float.to_i`, `floor`, `ceil`, `truncate` · `round(f)` / `round(f, digits)` | Integer · Integer / Float |
| `nan?` · `finite?` · `infinite?` | true/false · true/false · 1, -1, nil |
| `Float.to_r`, `rationalize` | Rational |

## String

| 操作 | 結果 |
|---|---|
| `+(a, b)`, `*(s, n)`, `%` | String |
| `== != < <= > >=` | true/false |
| `length`, `size`, `count(s, chars)`, `to_i(s, base = 10)` · `to_f` | Integer · Float |
| `upcase`, `downcase`, `capitalize`, `swapcase`, `reverse`, `strip`, `lstrip`, `rstrip`, `chomp`, `chop`, `to_s` | String |
| `sub(s, pat, repl)`, `gsub(...)` | String。repl は String（`\1` 可）、Hash、またはブロック `{ \|m\| ... }`。`sub!`, `gsub!` はその場で |
| `ljust(s, n, [pad])`, `rjust`, `center` · `tr(s, a, b)`, `delete(s, chars)`, `squeeze(s, [chars])`, `succ`, `next` | String |
| `empty?`, `include?(s, t)`, `start_with?`, `end_with?`, `match?(s, re)`, `casecmp?` | true/false |
| `chars`, `lines`, `bytes`, `split(s, [sep, [limit]])`, `scan(s, re)` | Array |
| `index(s, t, [start])`, `rindex`, `byteindex` | Integer か nil |
| `match(s, re, [pos])` | MatchData か nil |
| `ord` · `hex` · `oct` · `to_sym`, `intern` | Integer · Symbol |
| `byteslice(s, i, [n])`, `b`, `force_encoding(s, enc)`, `encode`, `encoding`, `valid_encoding?`, `unpack(s, fmt)`, `unpack1` | バイト列と変換（Ruby と同じ） |
| `each_line(s) { }`, `each_char(s) { }`, `each_byte` | s（ブロック） |

## Array

| 操作 | 結果 |
|---|---|
| `Array[...]` · `Array.new(n)`, `Array.new(n, v)`, `Array.new(n) { \|i\| }` | 新しい Array |
| `length`, `size` · `empty?`, `include?(a, x)` | Integer · true/false |
| `push(a, *xs)`, `append`, `unshift`, `concat(a, b)`, `insert(a, i, *xs)`, `delete_if`, `clear` | a（その場で） |
| `first`, `last`, `min`, `max`, `pop`, `shift`, `at(a, i)`, `sample`, `delete(a, x)`, `delete_at(a, i)` | 要素、または nil |
| `first(a, n)`, `last(a, n)`, `shift(a, n)`, `take`, `drop`, `slice(a, i, n)` | 新しい Array |
| `fetch(a, i, [default])` | 要素、既定値、または `IndexError` |
| `join(a, [sep])` | String |
| `sum(a, [init])` | 和。要素は数（または `Arithmetic` を include する型）。空なら `init`（既定 0） |
| `reverse`, `sort`, `sort_by`, `uniq`, `compact`, `flatten`, `rotate`, `shuffle`, `dup` | 新しい Array |
| `each`, `each_with_index`, `each_slice(a, n)`, `each_cons(a, n)`, `cycle` | a（ブロック。ブロック無しの `each_slice` などは Array を返す） |
| `map`, `flat_map`, `select`, `filter`, `reject`, `partition`, `group_by`, `tally`, `to_h`, `zip`, `product` | 新しい Array / Hash / Tuple |
| `any?`, `all?`, `none?`, `count` | true/false · Integer（ブロックは省略可） |
| `reduce(a, init) { }`, `inject`, `each_with_object(a, memo) { }` | 累積値 |
| `find`, `detect`, `min_by`, `max_by`, `index(a, x)`, `find_index`, `assoc`, `rassoc` | 要素か nil · Integer か nil |
| `map!`, `select!`, `reject!`, `sort!`, `uniq!`, `compact!`, `flatten!`, `reverse!`, `slice!`, `fill`, `replace` | a（その場で。要素型を変えないものに） |
| `pack(a, fmt)` | String |

## Tuple, Range

| 操作 | 結果 |
|---|---|
| `Tuple.size`, `length` · `to_a` · `max`, `min` · `minmax` | Integer · Array · 要素（nil にならない） · `[min, max]` |
| `Range.each`, `each_with_index`, `step(r, n)` | r（ブロック） |
| `to_a`, `map`, `select`, `filter`, `reject`, `zip` | Array |
| `reduce`, `inject` · `sum` · `size` · `count` | 累積値 · Integer |
| `any?`, `all?`, `none?` · `find`, `detect` · `include?`, `cover?`, `member?`, `exclude_end?` | true/false · 要素か nil · true/false |
| `first`, `last`, `min`, `max`, `begin`, `end` | 要素か nil（`first(r, n)`、`last(r, n)` は Array） |

## Hash, Set

| 操作 | 結果 |
|---|---|
| `Hash[k => v, ...]` · `Hash.new([default])` · `Set[...]` | 新しい Hash · Set |
| `length`, `size`, `empty?`, `key?`, `has_key?`, `include?`, `member?`, `value?` | Integer · true/false |
| `fetch(h, k, [default])` · `dig(h, k)` · `delete(h, k)` · `key(h, v)` | 値 · 値か nil · 消した値か nil · キーか nil |
| `store(h, k, v)`, `merge!`, `update`, `clear`, `transform_values!`, `transform_keys!`, `select!`, `reject!`, `compact!` | その場で |
| `merge(a, b)`, `invert`, `select`, `filter`, `reject`, `transform_values`, `transform_keys`, `compact`, `slice`, `except` | 新しい Hash |
| `keys` · `values` · `to_a` · `map` · `sort_by` · `group_by` · `partition` | Array |
| `each`, `each_pair`, `each_key`, `each_value` | h（ブロック） |
| `any?`, `all?`, `none?`, `count`, `sum`, `find`, `detect`, `min_by`, `max_by` | ブロック付き |
| `Set.add(s, x)`, `add?`, `delete`, `merge`, `subtract`, `clear` · `to_a`, `each`, `map`, `select`, `filter`, `reject` | s（その場で）· Array |
| `union`, `intersection`, `difference`, `\|`, `&`, `-` · `subset?`, `superset?`, `disjoint?`, `intersect?` | 新しい Set · true/false |

## Regexp, MatchData, Symbol, Time, Math

| 操作 | 結果 |
|---|---|
| `Regexp.new(s, flags = "")` · `escape(s)` · `source(r)` · `match(r, s, [pos])` · `match?` | Regexp · String · String · MatchData か nil · true/false（flags は `imx` の文字） |
| `MatchData.captures` · `named_captures` · `names` · `to_a` · `to_s`, `pre_match`, `post_match` · `begin(m, i)`, `end(m, i)` | Array · Hash · Array · Array · String · Integer |
| `Symbol.to_s` · `length`, `size` · `to_proc` は無い | String · Integer |
| `Time.now` · `at(seconds, [in:])` · `new(y, [m, d, h, min, s, zone])` · `utc(t)`, `getutc` · `getlocal(t, [zone])`, `localtime` | Time |
| `year`, `month`, `day`, `hour`, `min`, `sec`, `wday`, `yday`, `to_i`, `utc_offset` · `to_f` · `to_s`, `strftime(t, fmt)` · `zone` · `utc?` | Integer · Float · String · String か nil · true/false |
| `Math.sqrt`, `cbrt`, `sin`, `cos`, `tan`, `atan`, `exp`, `log`, `log2`, `log10`, `atan2(y, x)`, `hypot(x, y)` | Float |

## Rational, Complex

| 操作 | 結果 |
|---|---|
| `Rational(a, [b])` · `Integer.to_r` · `Float.to_r` · `Float.rationalize` | Rational |
| `Rational.numerator`, `denominator`, `to_i`, `floor`, `ceil`, `round`, `truncate` · `to_f` · `abs` | Integer · Float · Rational |
| `Complex(re, [im])` · `Complex.real`, `imaginary` · `abs`, `arg` · `conjugate` · `rectangular` · `polar` | Complex · 実数 · Float · Complex · `[re, im]` · `[abs, arg]` |
| `Integer.fdiv(a, b)` | Float |

## File, Dir, IO, ENV, Process

| 操作 | 結果 |
|---|---|
| `File.read(path)` · `readlines` · `write(path, s)` · `exist?`, `file?`, `directory?`, `symlink?`, `zero?`, `empty?`, `readable?`, `writable?`, `executable?`, `absolute_path?` | String · Array · Integer · true/false |
| `File.size`, `mtime`, `atime`, `ftype` · `rename`, `symlink`, `link`, `readlink`, `unlink`, `delete`, `chmod`, `utime` | Integer · Time · String · ... |
| `File.basename(p, [suffix])`, `dirname(p, [levels])`, `extname`, `join(*parts)`, `expand_path(p, [dir])`, `absolute_path`, `realpath` · `split(p)` | String · `[dir, base]` |
| `File.open(path, mode = "r", [perm])` · `File.open(...) { \|io\| }` | IO · ブロックの値（閉じる） |
| `Dir.children`, `entries` · `glob(pat, [base:])` · `each_child(path) { }` · `exist?`, `empty?` · `mkdir(path, [mode])`, `rmdir` · `pwd`, `home`, `tmpdir` · `mktmpdir([prefix, [dir]])` | Array of String · ... |
| `IO.puts(io, ...)`, `print`, `write(io, s)` · `gets(io)`, `read(io, [n])`, `readlines`, `getc` · `each_line(io) { }` · `eof?`, `closed?`, `tty?` · `flush`, `close` · `seek(io, off, [whence])`, `pos`, `rewind`, `truncate`, `size` | nil · String か nil · ... |
| `ENV.fetch(name, [default])`, `get(name)`, `set(name, v)`, `key?`, `delete`, `to_h`, `keys` | String · ... |
| `Process.clock_gettime(Process.CLOCK_MONOTONIC)`, `pid` | Float · Integer |
| `Open3.capture2(cmd, ...)`, `capture2e`, `capture3` | `[out, status]` などの Tuple |
| `Zlib.inflate`, `deflate`, `gzip`, `gunzip` | String |

閉じた IO、またはその向きに開いていない IO の読み書きは `IOError` です。`IO.stderr` への書き込みは stdout を先に flush するので、行の順序が保たれます。

## スレッドとソケット

| 操作 | 結果 |
|---|---|
| `Thread.new { ... }` · `Thread.value(t)` · `join(t, [limit])` · `alive?(t)` · `current` · `kill(t)` · `raise(t, msg)` | Thread · ブロックの値（待つ。スレッドのエラーはここで上がる）· t か nil · true/false |
| `Mutex.new` · `synchronize(m) { }` · `lock`, `unlock`, `try_lock`, `locked?`, `owned?` | Mutex · ブロックの値 |
| `Queue.new` · `push(q, x)` · `pop(q, [timeout])` · `close`, `size`, `empty?`, `closed?` | Queue · q · 最古の要素（待つ。閉じて空なら nil） |
| `TCPServer.new(host, port)` · `accept(s)` · `port(s)` · `close(s)` | TCPServer（port 0 は空きを選ぶ）· Socket（待つ）· Integer · nil |
| `Socket.connect(host, port, [timeout])` · `connect_ssl(host, port, [timeout])` · `set_timeout(s, secs)` | Socket（`connect_ssl` は TLS、相手を検証） |
| `Socket.gets(s)` · `read(s, n)` · `write(s, str)` · `close_write(s)` · `close(s)` | String か nil · String か nil · Integer · nil · nil |

- **スレッドの変数。** ブロックは周りの変数を共有します。スレッドでは、`Thread.new` を囲むブロックの変数（引数とローカル）とスレッドブロック自身の変数は開始時に複製され、関数の変数は共有のままです。`Array.map(xs) { |w| Thread.new { ... w ... } }` は各スレッドに自分の `w` を与え、共有カウンタは `Mutex.synchronize` の中で更新する関数の変数にします。
- **スレッドブロックを抜ける。** `Thread.new` のブロックからの `break` と `return` はエラー（`LocalJumpError`）です。`next v` は `v` で終えます。
- **エラー。** スレッドの中のエラーは `Thread.value` か `Thread.join` で上がります。join されないスレッドは失敗しても黙って終わり、メインが終わればすべてのスレッドが止まります。
- **検査。** 型推論はスレッドのブロックを `Thread.new` で 1 度走らせます。その値が `Thread.value` の型、Queue の要素型は push されたものの和です（`Queue.pop` は nil を加える）。交互実行は解析せず、各操作が実行時に引数を検査します。

## 型付き Array

`Integer[...]`、`Float[...]`、`Rational[...]`、`Complex[...]`、`String[...]`、`Symbol[...]`、`Tuple[...]`、および各クラス `D` の `D[...]` は、要素型がその型の Array を作ります（[値と型](03-values.md)）。
