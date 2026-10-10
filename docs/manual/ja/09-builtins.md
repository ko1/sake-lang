# 組み込み操作

組み込みの操作は約 550 あり、名前は Ruby のコアライブラリと同じです。この章は名前空間ごとの案内です: その型が何のためにあるか、最初に手が伸びる 2〜3 の操作、短い例、そして詳細のある章へのリンクを置きます。**各操作の正確な署名、引数、nil になる場合、投げる例外、例は、第 2 部「組み込みリファレンス」に型ごとに 1 章ずつあります**（[Array](ref/Array.md)、[String](ref/String.md)、[Hash](ref/Hash.md)、[Kernel](ref/Kernel.md)、…）。

各節の表は「何をしたいか」で操作をまとめたもので、「結果」の列は結果の型です。「ブロック」と記したものはブロックが必須です。`[x]` は省略できる引数です。演算子（`+`、`<`、`[]`）の規則は[演算子と添字](05-operators.md)に、各型の値の性質は[値と型](03-values.md)にあります。

## Kernel

Kernel は、プログラムのどこからでも名前だけで呼べる操作の集まりです。`puts(x)`、`Integer(s)`、`loop { }` のように書き、`Kernel.puts(x)` と書く必要はありません。最初に使うのは出力の `p` と `puts`、文字列から数への変換 `Integer(s)`、繰り返しの `loop` です。詳細は [Kernel](ref/Kernel.md)。

```ruby
puts("total:", 3)
# => total:
# => 3
p(format("%05.1f", 3.14159))     # => "003.1"
p(Integer("42") + 1)             # => 43
x = loop { break 7 }
p(x)                             # => 7
p(Math.PI > 3)                   # => true
```

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

- **定数は操作。** `Math::PI`、`Math::E`、`Float::INFINITY`、`Float::NAN`、`Float::EPSILON`、`Float::MAX`、`Float::MIN` は、`ARGV` と同じく操作として読みます（`Math.PI`）。Sake に値の定数は無く、他の入れ子の名前もありません。

## Integer / Float

Integer は上限の無い整数、Float は倍精度の浮動小数点数です。算術と比較は演算子で書き、`Integer.to_s(n, 16)` のような変換と、`Integer.times(n) { }` のような繰り返しを型を付けて呼びます。最初に使うのは `/` と `%`（Integer どうしは整数除算）、`Float.round`、`Integer.times` です。詳細は [Integer](ref/Integer.md)、[Float](ref/Float.md)、[Arithmetic](ref/Arithmetic.md)。

```ruby
p(7 / 2)                         # => 3
p(7.0 / 2)                       # => 3.5
p(Integer.divmod(7, 2))          # => [3, 1]
p(Integer.to_s(255, 16))         # => "ff"
p(Float.round(3.14159, 2))       # => 3.14
Integer.times(3) { |i| print(i) }
puts                             # => 012
```

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

- **どの実数も取る丸め。** `Arithmetic.round(x)`、`floor`、`ceil`、`truncate`（省略可能な桁数付き）、`abs`、`to_f`、`to_i`、`zero?` は、Ruby の `x.round` と同じくどの実数（Integer, Float, Rational）も取り、結果の型は x に従います（桁なしの round は Integer）。`Float.round` は Float だけを名乗ります。

## String

String はエンコーディングを持つ文字の並びで、可変です。名前が `!` で終わる操作は主語をその場で変え、他は新しい String を返します。最初に使うのは `String.split`、`String.sub`/`gsub`、`String.include?` と、連結の `+` です。詳細は [String](ref/String.md)。

```ruby
s = "Hello, World"
p(String.length(s))              # => 12
p(String.upcase(s))              # => "HELLO, WORLD"
p(String.split(s, ", "))         # => ["Hello", "World"]
p(String.sub(s, "World", "Sake"))   # => "Hello, Sake"
p(String.include?(s, "World"))   # => true
p(String.index(s, "x"))          # => nil
p(s + "!")                       # => "Hello, World!"
```

| 目的 | 操作 | 結果 |
|---|---|---|
| 連結・繰り返し・書式 | `+(a, b)`, `*(s, n)`, `%` | String |
| 比較 | `== != < <= > >=` | true/false |
| 長さと数 | `length`, `size`, `count(s, chars)`, `to_i(s, base = 10)` · `to_f` | Integer · Float |
| 変形 | `upcase`, `downcase`, `capitalize`, `swapcase`, `reverse`, `strip`, `lstrip`, `rstrip`, `chomp`, `chop`, `to_s` | String |
| 置換 | `sub(s, pat, repl)`, `gsub(...)` | String。`sub!`, `gsub!` はその場で |
| 詰め物と文字の置き換え | `ljust(s, n, [pad])`, `rjust`, `center` · `tr(s, a, b)`, `delete(s, chars)`, `squeeze(s, [chars])`, `succ`, `next` | String |
| 問い合わせ | `empty?`, `include?(s, t)`, `start_with?`, `end_with?`, `match?(s, re)`, `casecmp?` | true/false |
| 分割 | `chars`, `lines`, `bytes`, `split(s, [sep, [limit]])`, `scan(s, re)` | Array |
| 位置 | `index(s, t, [start])`, `rindex`, `byteindex` | Integer か nil |
| 正規表現の一致 | `match(s, re, [pos])` | MatchData か nil |
| 他の型へ | `ord` · `hex` · `oct` · `to_sym`, `intern` | Integer · Symbol |
| バイト列と変換 | `byteslice(s, i, [n])`, `b`, `force_encoding(s, enc)`, `encode`, `encoding`, `valid_encoding?`, `unpack(s, fmt)`, `unpack1` | Ruby と同じ |
| 繰り返し | `each_line(s) { }`, `each_char(s) { }`, `each_byte` | s（ブロック） |

- **置換の repl。** `sub`、`gsub` の repl は、String（`\1` 可）、Hash（一致 => 置換）、またはブロック `{ |m| ... }` です。

## Array

Array は長さが変わる並びです。`Array[1, 2]` で作ります（リテラル `[1, 2]` は Tuple です）。最初に使うのは `Array.push`、`Array.each`、`Array.map` と `Array.select` です。詳細は [Array](ref/Array.md)。

```ruby
xs = Array[3, 1, 2]
Array.push(xs, 5)
p(xs)                                      # => [3, 1, 2, 5]
p(Array.map(xs) { |x| x * 2 })             # => [6, 2, 4, 10]
p(Array.select(xs) { |x| x > 1 })          # => [3, 2, 5]
p(Array.sort(xs))                          # => [1, 2, 3, 5]
p(Array.reduce(xs, 0) { |acc, x| acc + x })   # => 11
p(Array.first(xs))                         # => 3
p(Array.join(xs, "-"))                     # => "3-1-2-5"
p(Array.tally(Array["a", "b", "a"]))       # => {"a" => 2, "b" => 1}
```

| 目的 | 操作 | 結果 |
|---|---|---|
| 作る | `Array[...]` · `Array.new(n)`, `Array.new(n, v)`, `Array.new(n) { \|i\| }` | 新しい Array |
| 長さと問い合わせ | `length`, `size` · `empty?`, `include?(a, x)` | Integer · true/false |
| 足す・消す（その場で） | `push(a, *xs)`, `append`, `unshift`, `concat(a, b)`, `insert(a, i, *xs)`, `delete_if`, `clear` | a |
| 1 要素を取る | `first`, `last`, `min`, `max`, `pop`, `shift`, `at(a, i)`, `sample`, `delete(a, x)`, `delete_at(a, i)` | 要素、または nil |
| 部分を取る | `first(a, n)`, `last(a, n)`, `shift(a, n)`, `take`, `drop`, `slice(a, i, n)` | 新しい Array |
| 無ければ失敗 | `fetch(a, i, [default])` | 要素、既定値、または `IndexError` |
| 文字列に | `join(a, [sep])` | String |
| 合計 | `sum(a, [init])` | 和（下記） |
| 並べ替えなど | `reverse`, `sort`, `sort_by`, `uniq`, `compact`, `flatten`, `rotate`, `shuffle`, `dup` | 新しい Array |
| 繰り返し | `each`, `each_with_index`, `each_slice(a, n)`, `each_cons(a, n)`, `cycle` | a（ブロック） |
| 写像と選別 | `map`, `flat_map`, `select`, `filter`, `reject`, `partition`, `group_by`, `tally`, `to_h`, `zip`, `product` | 新しい Array / Hash / Tuple |
| 判定と数え上げ | `any?`, `all?`, `none?`, `count` | true/false · Integer（ブロックは省略可） |
| 畳み込み | `reduce(a, init) { }`, `inject`, `each_with_object(a, memo) { }` | 累積値 |
| 探す | `find`, `detect`, `min_by`, `max_by`, `index(a, x)`, `find_index`, `assoc`, `rassoc` | 要素か nil · Integer か nil |
| 書き換え（その場で） | `map!`, `select!`, `reject!`, `sort!`, `uniq!`, `compact!`, `flatten!`, `reverse!`, `slice!`, `fill`, `replace` | a |
| バイト列に | `pack(a, fmt)` | String |

- **`sum`。** 要素は数、または `Arithmetic` を include する型です。空なら `init`（既定 0）です。
- **ブロック無しの繰り返し。** `each_slice` などをブロック無しで呼ぶと Array を返します。
- **その場の書き換え。** `map!` などは要素型を変えない写像に使います。

## Tuple, Range

Tuple は長さと各位置の型が決まった並びで、リテラル `[1, "a"]` が作ります。Range は 2 つの端の組で、`1..5`、`1...5`、終端の無い `1..` があります。Tuple の操作は少なく、`Tuple.to_a` で Array にして扱うのが普通です。Range は `Range.each` で数を数え、`Range.to_a` と `Range.include?` をよく使います。詳細は [Tuple](ref/Tuple.md)、[Range](ref/Range.md)。

```ruby
t = [1, "a"]
p(Tuple.size(t))                 # => 2
p(Tuple.to_a(t))                 # => [1, "a"]
p(Tuple.max([3, 7, 5]))          # => 7
p(Range.to_a(1..5))              # => [1, 2, 3, 4, 5]
p(Range.sum(1..5))               # => 15
p(Range.include?(1...5, 5))      # => false
p(Range.map(1..3) { |i| i * i })    # => [1, 4, 9]
p(Range.first(1.., 3))           # => [1, 2, 3]
```

| 操作 | 結果 |
|---|---|
| `Tuple.size`, `length` · `to_a` · `max`, `min` · `minmax` | Integer · Array · 要素（nil にならない） · `[min, max]` |
| `Range.each`, `each_with_index`, `step(r, n)` | r（ブロック） |
| `to_a`, `map`, `select`, `filter`, `reject`, `zip` | Array |
| `reduce`, `inject` · `sum` · `size` · `count` | 累積値 · Integer |
| `any?`, `all?`, `none?` · `find`, `detect` · `include?`, `cover?`, `member?`, `exclude_end?` | true/false · 要素か nil · true/false |
| `first`, `last`, `min`, `max`, `begin`, `end` | 要素か nil（`first(r, n)`、`last(r, n)` は Array） |

## Hash, Set

Hash はキーから値への対応で、`Hash["a" => 1]` か `Hash.new(default)` で作ります（`{a: 1}` は Record です）。Set は重複の無い要素の集まりで、`Set[1, 2]` で作ります。最初に使うのは添字 `h[k]` と `h[k] = v`、`Hash.each`、`Hash.fetch`、そして `Set.add` と `Set.include?` です。詳細は [Hash](ref/Hash.md)、[Set](ref/Set.md)。

```ruby
h = Hash["a" => 1]
h["b"] = 2
p(h)                                       # => {"a" => 1, "b" => 2}
p(h["c"])                                  # => nil
p(Hash.fetch(h, "a"))                      # => 1
p(Hash.map(h) { |k, v| [k, v * 10] })      # => [["a", 10], ["b", 20]]
counts = Hash.new(0)
counts["x"] += 1
p(counts)                                  # => {"x" => 1}
s = Set[1, 2]
Set.add(s, 2)
p(s)                                       # => Set[1, 2]
p(Set.include?(s, 2))                      # => true
p(Set.union(s, Set[9]))                    # => Set[1, 2, 9]
```

| 目的 | 操作 | 結果 |
|---|---|---|
| 作る | `Hash[k => v, ...]` · `Hash.new([default])` · `Set[...]` | 新しい Hash · Set |
| 長さと問い合わせ | `length`, `size`, `empty?`, `key?`, `has_key?`, `include?`, `member?`, `value?` | Integer · true/false |
| 1 つを取る | `fetch(h, k, [default])` · `dig(h, k)` · `delete(h, k)` · `key(h, v)` | 値 · 値か nil · 消した値か nil · キーか nil |
| 書き換え（その場で） | `store(h, k, v)`, `merge!`, `update`, `clear`, `transform_values!`, `transform_keys!`, `select!`, `reject!`, `compact!` | h |
| 新しい Hash | `merge(a, b)`, `invert`, `select`, `filter`, `reject`, `transform_values`, `transform_keys`, `compact`, `slice`, `except` | 新しい Hash |
| Array に | `keys` · `values` · `to_a` · `map` · `sort_by` · `group_by` · `partition` | Array |
| 繰り返し | `each`, `each_pair`, `each_key`, `each_value` | h（ブロック） |
| 判定と探索 | `any?`, `all?`, `none?`, `count`, `sum`, `find`, `detect`, `min_by`, `max_by` | ブロック付き |
| Set の書き換え（その場で） | `Set.add(s, x)`, `add?`, `delete`, `merge`, `subtract`, `clear` | s |
| Set から Array へ | `to_a`, `each`, `map`, `select`, `filter`, `reject` | Array |
| 集合演算 | `union`, `intersection`, `difference`, `\|`, `&`, `-` · `subset?`, `superset?`, `disjoint?`, `intersect?` | 新しい Set · true/false |

## Regexp, MatchData, Symbol, Time, Math

Regexp は正規表現で、リテラル `/\d+/` が作ります。一致の結果が MatchData で、一致しなければ nil です。Symbol は名前そのものの値（`:name`）、Time は 1 つの時刻、Math は初等関数の集まりです。最初に使うのは `Regexp.match` と `m[1]`、`String.scan`、`Time.now`、`Math.sqrt` です。詳細は [Regexp](ref/Regexp.md)、[MatchData](ref/MatchData.md)、[Symbol](ref/Symbol.md)、[Time](ref/Time.md)、[Math](ref/Math.md)。

```ruby
m = Regexp.match(/(\d+)-(\d+)/, "tel 03-1234")
if m
  p(m[1])                        # => "03"
  p(MatchData.captures(m))       # => ["03", "1234"]
end
p(String.scan("a1 b22", /\d+/))  # => ["1", "22"]
p(Symbol.to_s(:name))            # => "name"
t = Time.at(0, in: "UTC")
p(Time.year(t))                  # => 1970
p(Time.strftime(t, "%Y-%m-%d"))  # => "1970-01-01"
p(Math.sqrt(16))                 # => 4.0
```

| 操作 | 結果 |
|---|---|
| `Regexp.new(s, flags = "")` · `escape(s)` · `source(r)` · `match(r, s, [pos])` · `match?` | Regexp · String · String · MatchData か nil · true/false（flags は `imx` の文字） |
| `MatchData.captures` · `named_captures` · `names` · `to_a` · `to_s`, `pre_match`, `post_match` · `begin(m, i)`, `end(m, i)` | Array · Hash · Array · Array · String · Integer |
| `Symbol.to_s` · `length`, `size` | String · Integer |
| `Time.now` · `at(seconds, [in:])` · `new(y, [m, d, h, min, s, zone])` · `utc(t)`, `getutc` · `getlocal(t, [zone])`, `localtime` | Time |
| `year`, `month`, `day`, `hour`, `min`, `sec`, `wday`, `yday`, `to_i`, `utc_offset` · `to_f` · `to_s`, `strftime(t, fmt)` · `zone` · `utc?` | Integer · Float · String · String か nil · true/false |
| `Math.sqrt`, `cbrt`, `sin`, `cos`, `tan`, `atan`, `exp`, `log`, `log2`, `log10`, `atan2(y, x)`, `hypot(x, y)` | Float |

- **`Symbol.to_proc` は無い。** ブロックは値ではないので、`&:name` は書けません（[関数とブロック](04-functions.md)）。

## Rational, Complex

Rational は常に既約の有理数（`1/3r`）、Complex は複素数（`1 + 2i`）です。どちらも算術演算子がそのまま使え、`Rational(1, 3)` と `Complex(1, 2)` は Kernel の操作です。詳細は [Rational](ref/Rational.md)、[Complex](ref/Complex.md)。

```ruby
r = Rational(1, 3)
p(r + 1/6r)                      # => (1/2)
p(Rational.numerator(r))         # => 1
p(Rational.to_f(r))              # => 0.3333333333333333
c = Complex(1, 2)
p(c * c)                         # => (-3+4i)
p(Complex.abs(Complex(3, 4)))    # => 5.0
p(Integer.fdiv(7, 2))            # => 3.5
```

| 操作 | 結果 |
|---|---|
| `Rational(a, [b])` · `Integer.to_r` · `Float.to_r` · `Float.rationalize` | Rational |
| `Rational.numerator`, `denominator`, `to_i`, `floor`, `ceil`, `round`, `truncate` · `to_f` · `abs` | Integer · Float · Rational |
| `Complex(re, [im])` · `Complex.real`, `imaginary` · `abs`, `arg` · `conjugate` · `rectangular` · `polar` | Complex · 実数 · Float · Complex · `[re, im]` · `[abs, arg]` |
| `Integer.fdiv(a, b)` | Float |

## File, Dir, IO, ENV, Process

File と Dir はパス（String）でファイルとディレクトリを扱う操作の集まりで、値はありません。IO は開いたファイルと標準ストリーム（`IO.stdin`、`IO.stdout`、`IO.stderr`）の型です。ENV は環境変数、Process はプロセスの情報と時計、Open3 は子プロセス、Zlib は圧縮です。最初に使うのは `File.read`、`File.write`、`File.open(path) { |io| }`、`Dir.glob` です。詳細は [File](ref/File.md)、[Dir](ref/Dir.md)、[IO](ref/IO.md)、[ENV](ref/ENV.md)、[Process](ref/Process.md)、[Open3](ref/Open3.md)、[Zlib](ref/Zlib.md)。

```ruby
dir = Dir.mktmpdir
path = File.join(dir, "notes.txt")
p(File.write(path, "one\ntwo\n"))          # => 8
p(File.readlines(path))                    # => ["one\n", "two\n"]
File.open(path, "a") { |io| IO.puts(io, "three") }
p(Array.length(File.readlines(path)))      # => 3
p(Dir.children(dir))                       # => ["notes.txt"]
p(ENV.fetch("NO_SUCH_VAR", "default"))     # => "default"
out, status = Open3.capture2("echo", "hi")
p(out)                                     # => "hi\n"
File.delete(path)
Dir.rmdir(dir)
```

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

- **閉じた IO。** 閉じた IO、またはその向きに開いていない IO の読み書きは `IOError` です。
- **stderr の順序。** `IO.stderr` への書き込みは stdout を先に flush するので、行の順序が保たれます。

## スレッドとソケット

Thread はブロックを並行に走らせ、Mutex が排他、Queue がスレッド間の受け渡しを担います。TCPServer と Socket は TCP の待ち受けと接続です。最初に使うのは `Thread.new { }` と `Thread.value`、`Mutex.synchronize`、`Queue.push`/`pop` です。詳細は [Thread](ref/Thread.md)、[Mutex](ref/Mutex.md)、[Queue](ref/Queue.md)、[TCPServer](ref/TCPServer.md)、[Socket](ref/Socket.md)。

```ruby
count = 0
m = Mutex.new
ts = Array.map(Array[1, 2, 3]) { |w| Thread.new { Mutex.synchronize(m) { count += w }; w * 10 } }
p(Array.map(ts) { |t| Thread.value(t) })   # => [10, 20, 30]
p(count)                                   # => 6
q = Queue.new
producer = Thread.new { Range.each(1..3) { |i| Queue.push(q, i) }; Queue.close(q) }
got = Array[]
loop do
  x = Queue.pop(q)
  break if x == nil
  Array.push(got, x)
end
Thread.join(producer)
p(got)                                     # => [1, 2, 3]
```

| 操作 | 結果 |
|---|---|
| `Thread.new { ... }` · `Thread.value(t)` · `join(t, [limit])` · `alive?(t)` · `current` · `kill(t)` · `raise(t, msg)` | Thread · ブロックの値（待つ。スレッドのエラーはここで上がる）· t か nil · true/false |
| `Mutex.new` · `synchronize(m) { }` · `lock`, `unlock`, `try_lock`, `locked?`, `owned?` | Mutex · ブロックの値 |
| `Queue.new` · `push(q, x)` · `pop(q, [timeout])` · `close`, `size`, `empty?`, `closed?` | Queue · q · 最古の要素（待つ。閉じて空なら nil） |
| `TCPServer.new(host, port)` · `accept(s)` · `port(s)` · `close(s)` | TCPServer（port 0 は空きを選ぶ）· Socket（待つ）· Integer · nil |
| `Socket.connect(host, port, [timeout])` · `connect_ssl(host, port, [timeout])` · `set_timeout(s, secs)` | Socket（`connect_ssl` は TLS、相手を検証） |
| `Socket.gets(s)` · `read(s, n)` · `write(s, str)` · `close_write(s)` · `close(s)` | String か nil · String か nil · Integer · nil · nil |

- **スレッドの変数。** ブロックは周りの変数を共有します。スレッドでは、`Thread.new` を囲むブロックの変数（引数とローカル）とスレッドブロック自身の変数は開始時に複製され、関数の変数は共有のままです。上の例の `Array.map(xs) { |w| Thread.new { ... w ... } }` は各スレッドに自分の `w` を与え、共有カウンタ `count` は `Mutex.synchronize` の中で更新する関数の変数です。
- **スレッドブロックを抜ける。** `Thread.new` のブロックからの `break` と `return` はエラー（`LocalJumpError`）です。`next v` は `v` で終えます。
- **エラー。** スレッドの中のエラーは `Thread.value` か `Thread.join` で上がります。join されないスレッドは失敗しても黙って終わり、メインが終わればすべてのスレッドが止まります。
- **検査。** 型推論はスレッドのブロックを `Thread.new` で 1 度走らせます。その値が `Thread.value` の型、Queue の要素型は push されたものの和です（`Queue.pop` は nil を加える）。交互実行は解析せず、各操作が実行時に引数を検査します。

## 型付き Array

`Integer[...]`、`Float[...]`、`Rational[...]`、`Complex[...]`、`String[...]`、`Symbol[...]`、`Tuple[...]`、および各クラス `D` の `D[...]` は、要素型がその型の Array を作ります（[値と型](03-values.md)）。書き込みは要素型と照合され、合わない値は静的には `type` の問題、実行時には `TypeError` です。

```ruby
xs = Integer[1, 2]
Array.push(xs, 3)
p(xs)                            # => [1, 2, 3]
Point = Struct.new(:x, :y)
pts = Point[Point.new(0, 0)]
p(Array.length(pts))             # => 1
p(String[])                      # => []
```

```ruby error
xs = Integer[1, 2]
Array.push(xs, "a")              # !> Array.push: an element must be Integer, but is String [type]
```
