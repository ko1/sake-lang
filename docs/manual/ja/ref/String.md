# String

String は Ruby の String と同じく、エンコーディングを持つ文字の並びです。リテラルは `"abc"`、`'abc'`、`"a#{x}"`（補間は値を `to_s` で表示します。[値と型](../03-values.md)）で、リテラルは UTF-8、評価のたびに新しい String を作ります。String は**可変**です: 名前が `!` で終わる操作と `concat`、`append_as_bytes`、`prepend`、`insert`、`replace`、`clear`、`setbyte`、`bytesplice`、`force_encoding` は主語をその場で変え、それ以外の操作は主語に触れず新しい String を返します。プログラムが変えられない String は Hash のキー、Set の要素、Symbol の名前（`Symbol.name`）、MatchData が持つ String（`MatchData.string`）、プログラムの引数（`ARGV`）で、それらをその場で変えようとすると実行時に `TypeError` です（`cannot change this String in place: it is a Hash key, a Set element, a Symbol's name, or a program argument`）。

操作はすべて型を付けて書きます: `String.upcase(s)` であって `s.upcase` ではありません。String に使える演算子は `+`（String, String）、`*`（String, Integer）、`%`（書式）、`==`、`!=`、`<`、`<=`、`>`、`>=`、`<=>`（String, String）、`=~`、`!~`（String, Regexp）、添字 `s[i]`、`s[i, n]`、`s[range]` です（[演算子と添字](../05-operators.md)）。以下の `String.+(x, y)` などは、その演算子を関数の形で呼ぶものです。`s[i] = v` はありません: String は添字への書き込みができず（静的に `type` の問題）、`String.sub!`、`String.insert`、`String.bytesplice`、`String.replace` で変えます。

多くの操作が「外れ」に **nil** を返します: `index`、`rindex`、`byteindex`、`byterindex`、`match`、`getbyte`、`casecmp`、`unpack1`、`slice!`、`sub!`、`gsub!`、および何も変わらなかったときに nil を返すその場の形（`upcase!`、`strip!`、`chomp!`、`tr!`、...）です。その結果を検査せずに使うことは `--strict` レベル 2 で `nil` の問題になります。添字の形 `s[i]`、`s[i, n]`、`s[range]`、`String.slice`、`String.byteslice` の nil だけは「外れの nil」（`index-nil`）で、レベル 3 でのみ報告されます（[概観](../01-overview.md)）。

Ruby との違い: `sub` と `gsub` には置換文字列かブロックが要ります。`MatchData` は `m[i]` で読みます（`$~`、`$1` はありません）。`scan`、`partition`、`rpartition` は Ruby が Array を返すところで Tuple を返します。`count`、`start_with?`、`end_with?`、`include?` は引数を 1 つだけ取ります（`chomp`、`delete`、`squeeze` はそれぞれの `!` 形と同じもの、つまり区切りや複数の集合を取れます）。反復（`each_char` など）にはブロックが要ります。[組み込みの操作](../09-builtins.md)の表に操作の一覧があります。

## String[]

`String[*Any]`

**String の Array** を作ります（String そのものではありません）。`Integer[]` や `Tuple[]` と同じ型付き Array で、要素はすべて String でなければならず、`Array.push` などの書き込みも毎回検査されます。String 以外の要素は静的に `type` の問題、実行時は `TypeError` です。空の String の Array は `String[]` です。

```ruby
names = String["a", "b"]
Array.push(names, "c")
p(names)                     # => ["a", "b", "c"]
p(Array.size(String[]))      # => 0
```

```ruby error
Array.push(String[], 1)      # !> Array.push: an element must be String, but is Integer
```

## length, size

`String.length(x)`

`String.size(x)`

文字の個数（Integer）。バイト数ではありません: `"héllo"` は 5 文字、6 バイト（`bytesize`）です。

```ruby
p(String.length("hello"))    # => 5
p(String.size("héllo"))      # => 5
p(String.size(""))           # => 0
```

## bytesize

`String.bytesize(x)`

その String のエンコーディングでのバイト数（Integer）。

```ruby
p(String.bytesize("héllo"))  # => 6
p(String.bytesize(""))       # => 0
```

## empty?

`String.empty?(x)`

文字が 1 つも無いとき true。

```ruby
p(String.empty?(""))         # => true
p(String.empty?(" "))        # => false
```

## +

`String.+(x, Any)`

`a + b` の関数形。`a` の文字に `b` の文字を続けた新しい String を返します。両辺とも String でなければならず、`"a" + 1` は静的に `type` の問題です（Ruby は `TypeError`）。どちらの被演算子も変わりません。

```ruby
s = "abc"
p(s + "d")                   # => "abcd"
p(String.+("a", "b"))        # => "ab"
p(s)                         # => "abc"
```

```ruby error
p("a" + 1)                   # !> the operands are (String, Integer)
```

## *

`String.*(x, Integer)`

`s * n` の関数形。`s` を `n` 回繰り返した新しい String（0 なら `""`）。負の `n` は演算子でも関数形でも `ArgumentError`（`negative argument`）で、rescue できます。

```ruby
p("ab" * 3)                  # => "ababab"
p(String.*("-", 0))          # => ""
begin
  p("ab" * -1)
rescue ArgumentError => e
  puts(Exception.message(e))     # => negative argument
end
```

```ruby error
p(String.*("ab", -1))        # !> ArgumentError: String.*: negative argument -1
```

## %

`String.%(x, Any)`

`fmt % value` の関数形で、`fmt` を書式とする Ruby の `format` です: `"%d items" % 3`。右辺は値 1 つ（Integer、Float、String、Symbol、nil、true、false）か、複数の指示子に対する値の Tuple（`"%s-%s" % [a, b]`）か、名前付き指示子 `%<name>d`、`%{name}` に対する Record または Symbol キーの Hash（`"%<a>05d" % {a: 42}`、`"%<a>05d" % Hash[a: 42]`）です。Array は静的に `type` の問題です。指示子は Ruby のもの（`%d`、`%s`、`%f`、`%x`、`%05d`、`%-4s`、`%.2f`、`%p`、...）。指示子に合わない値（`"%d" % "x"`）や値の不足は `ArgumentError`、Record や Hash に無い名前は `KeyError`（`key<b> not found`）、余った値は無視されます。

```ruby
p("%05d|%-4s|%.2f|%x" % [42, "ab", 3.14159, 255])   # => "00042|ab  |3.14|ff"
p("%d items" % 3)            # => "3 items"
p("%s" % :sym)               # => "sym"
p("%p" % nil)                # => "nil"
p(String.%("%03d", 7))       # => "007"
p("%<a>05d" % {a: 42})       # => "00042"
p("%{a}-%<b>s" % {a: 1, b: "x"})     # => "1-x"
p("%<a>05d" % Hash[a: 42])   # => "00042"
```

```ruby error
p("%<b>d" % {a: 42})         # !> KeyError: Arithmetic.%: key<b> not found
```

```ruby error
p("%d %d" % 1)               # !> ArgumentError: Arithmetic.%: too few arguments
```

## ==, !=

`String.==(x, Any)`

`String.!=(x, Any)`

両方が String で同じ文字の並びのとき true（`!=` はその否定）。同一性ではなく内容の比較です。右辺が別の型（Integer、Symbol、nil）なら、演算子でも関数形でもただ等しくないだけです: `String.==("a", 1)` は false、`String.!=("a", 1)` は true で、誤りにはなりません。

```ruby
p("a" == "a")                # => true
p("a" != "b")                # => true
p("1" == 1)                  # => false
p("a" == nil)                # => false
p(String.==("a", nil))       # => false
p(String.==("a", 1))         # => false
p(String.!=("a", 1))         # => true
```

## <, <=, >, >=

`String.<(x, Any)`

`String.<=(x, Any)`

`String.>(x, Any)`

`String.>=(x, Any)`

2 つの String を Ruby と同じくバイト単位で比べます: 大文字が先なので `"B" < "a"`、`"10" < "9"`、接頭辞は長い方より小さい。両辺とも String でなければならず、別の型との比較は静的に `type` の問題です。

```ruby
p("a" < "b")                 # => true
p("B" >= "a")                # => false
p("10" < "9")                # => true
p("ab" < "abc")              # => true
p(String.<=("a", "a"))       # => true
```

```ruby error
p("a" < 1)                   # !> the operands are (String, Integer)
```

## <=>

`String.<=>(x, Any)`

その比較の結果を -1、0、1 で返します。両辺とも String でなければならないので、結果が nil になることはありません（Ruby は String 以外に nil を返します）。

```ruby
p("a" <=> "b")               # => -1
p("a" <=> "a")               # => 0
p(String.<=>("b", "a"))      # => 1
```

## between?

`String.between?(x, String, String)`

`<` の順で `lo <= x <= hi` のとき true。

```ruby
p(String.between?("b", "a", "c"))   # => true
p(String.between?("z", "a", "c"))   # => false
```

## clamp

`String.clamp(x, String, String)`

`x` が `lo` と `hi` の間にあればそのまま、外れていれば近い方の端を返します。`lo > hi` は `ArgumentError` です。

```ruby
p(String.clamp("b", "a", "c"))      # => "b"
p(String.clamp("z", "a", "c"))      # => "c"
```

```ruby error
p(String.clamp("b", "c", "a"))      # !> ArgumentError: String.clamp: min argument must be less than or equal to max argument
```

## casecmp

`String.casecmp(x, String)`

ASCII 文字の大小を無視して 2 つの String を比べ、-1、0、1（Integer）を返します。2 つのエンコーディングが互換でないときは nil で、その結果を検査せずに使うことは `--strict` レベル 2 で `nil` の問題です。

```ruby
p(String.casecmp("a", "A"))         # => 0
p(String.casecmp("a", "B"))         # => -1
p(String.casecmp("a", String.encode("a", "UTF-16LE")))   # => nil
```

```ruby error
p(String.casecmp("a", "b") + 1)     # !> the operands may be nil
```

## casecmp?

`String.casecmp?(x, String)`

Unicode のケースフォールディングの後で 2 つが等しいとき true。結果は Boolean で nil にはなりません: エンコーディングが互換でないとき（Ruby のメソッドが nil を返し、`casecmp` も nil になるところ）は **false** です。

```ruby
p(String.casecmp?("a", "A"))        # => true
p(String.casecmp?("a", "b"))        # => false
p(String.casecmp?("a", String.encode("a", "UTF-16LE")))   # => false
```

## =~

`String.=~(x, Any)`

`s =~ re` の関数形。Regexp `re` が `s` に最初に一致する位置（Integer）、一致しなければ nil。右辺は Regexp でなければならず、String は静的に `type` の問題です。nil を検査せずに使うことは `--strict` レベル 2 で `nil` の問題です。`$~` は無いので、グループを読むには `String.match` を使います。

```ruby
p("hello" =~ /l+/)           # => 2
p("hello" =~ /z/)            # => nil
p(String.=~("ab", /b/))      # => 1
```

```ruby error
p(("abc" =~ /b/) + 1)        # !> the operands may be nil
```

## !~

`String.!~(x, Any)`

`s !~ re` の関数形。Regexp が一致しないとき true。

```ruby
p("hello" !~ /z/)            # => true
p(String.!~("ab", /b/))      # => false
```

## []

`String.[](x, Any, [Integer])`

`s[i]`、`s[i, n]`、`s[range]` の関数形。`s[i]` は位置 `i`（Integer。負の値は末尾から）の 1 文字の String、範囲外なら nil。`s[i, n]` は `i` から最大 `n` 文字の部分文字列で、`i` が末尾を越えるか `n` が負なら nil、`i` が長さに等しければ `""`。`s[range]` は Range の範囲の文字で、始点が末尾を越えていれば nil。Ruby と同じく String と Regexp も添字にでき、`s["b"]` はその最初の出現（新しい String）か nil、`s[/re/]` は最初の一致、`s[/re/, 1]` はそのグループです（`String.slice` と同じ。2026-10-11 から）。Float などの添字は静的に `type` の問題で、Range と個数の組は `TypeError` です。結果の型は `String | nil` で、この nil は「外れの nil」（`index-nil`）なので `--strict` レベル 3 でのみ報告されます。

```ruby
s = "hello"
p(s[1])                      # => "e"
p(s[-1])                     # => "o"
p(s[10])                     # => nil
p(s[1, 3])                   # => "ell"
p(s[5, 1])                   # => ""
p(s[6, 1])                   # => nil
p(s[1..2])                   # => "el"
p(s[2..])                    # => "llo"
p(String.[](s, 0))           # => "h"
```

```ruby
s = "hello world"
p(s["wor"])                  # => "wor"
p(s["xyz"])                  # => nil
p(s[/o w/])                  # => "o w"
p(s[/(\w+) (\w+)/, 2])        # => "world"
```

```ruby error
p("abc"[1.5])                # !> the index must be Integer, but is Float
```

## slice

`String.slice(x, Integer|Range|String|Regexp, [Integer])`

`s[i]`、`s[i, n]`、`s[range]` を操作として書いたもの。結果も nil（`index-nil`、レベル 3）も同じです。Ruby の `slice` と同じく、`slice!` が取るものも取れます: String はその最初の出現（新しい String）か nil、Regexp は最初の一致、第 2 引数にグループ番号を添えればそのグループの String（グループが一致に関与しなければ nil）です。String や Range の後に個数を添えると `TypeError` です。

```ruby
s = "hello"
p(String.slice(s, 1))        # => "e"
p(String.slice(s, 1, 2))     # => "el"
p(String.slice(s, 1..2))     # => "el"
p(String.slice(s, 9))        # => nil
p(String.slice(s, "ll"))     # => "ll"
p(String.slice(s, "zz"))     # => nil
p(String.slice(s, /l+/))     # => "ll"
p(String.slice(s, /(l)(o)/, 2))      # => "o"
```

```ruby error
p(String.slice("hello", "ll", 1))    # !> TypeError: String.slice: no implicit conversion of String into Integer
```

## slice!

`String.slice!(x, Integer|Range|String|Regexp, [Integer])`

`s[i]`、`s[i, n]`、`s[range]` の部分を主語から**その場で**取り除き、それを返します。String を渡すとその最初の出現を、Regexp なら最初の一致を取り除きます。取り除くものが無いとき（末尾を越えた添字、現れない String や Regexp）は nil で、主語は変わりません。その結果を検査せずに使うことは `--strict` レベル 2 で `nil` の問題です。

```ruby
s = "hello"
p(String.slice!(s, 0))       # => "h"
p(String.slice!(s, /l+/))    # => "ll"
p(String.slice!(s, "zz"))    # => nil
p(s)                         # => "eo"
```

```ruby error
s = "hello"
c = String.slice!(s, 1)
p(String.upcase(c))          # !> argument 1 may be nil
```

## byteslice

`String.byteslice(x, Integer|Range, [Integer])`

バイト位置 `i` のバイト（1 バイトの String）、`i` から `n` バイト、またはバイト位置の Range の範囲のバイト列。主語のエンコーディングのままなので、多バイト文字を切ると不正な String になりえます。`i`（または Range の始点）が末尾を越えるか `n` が負なら nil（`index-nil`、レベル 3）。Ruby と同じです。

```ruby
p(String.byteslice("héllo", 1))      # => "\xC3"
p(String.byteslice("héllo", 1, 2))   # => "é"
p(String.byteslice("héllo", 1..2))   # => "é"
p(String.byteslice("hello", 9..10))  # => nil
p(String.byteslice("héllo", 9))      # => nil
```

## getbyte

`String.getbyte(x, Integer)`

バイト位置 `i`（負の値は末尾から）のバイト（0..255 の Integer）、範囲外なら nil。その結果を検査せずに使うことは `--strict` レベル 2 で `nil` の問題です。

```ruby
s = "héllo"
p(String.getbyte(s, 0))      # => 104
p(String.getbyte(s, 1))      # => 195
p(String.getbyte(s, -1))     # => 111
p(String.getbyte(s, 99))     # => nil
```

```ruby error
p(String.getbyte("a", 5) + 1)        # !> the operands may be nil
```

## setbyte

`String.setbyte(x, Integer, Integer)`

バイト位置 `i` にバイト `b` を**その場で**格納し（Ruby と同じく `b` の下位 8 ビット）、`b` を返します。範囲外の位置は `IndexError` です。

```ruby
s = "abc"
p(String.setbyte(s, 0, 65))  # => 65
p(s)                         # => "Abc"
```

```ruby error
p(String.setbyte("abc", 10, 1))      # !> IndexError: String.setbyte: index 10 out of string
```

## bytesplice

`String.bytesplice(x, Integer, Integer, String)`

バイト位置 `i` から `n` バイトを String `str` で**その場で**置き換え、主語を返します。範囲外の位置は `IndexError`。位置は文字の境界になければなりません。

```ruby
s = "hello"
p(String.bytesplice(s, 0, 2, "J"))   # => "Jllo"
p(s)                                 # => "Jllo"
```

```ruby error
p(String.bytesplice("abc", 10, 1, "x"))   # !> IndexError: String.bytesplice: index 10 out of string
```

## upcase, downcase, capitalize, swapcase

`String.upcase(x)`

`String.downcase(x)`

`String.capitalize(x)`

`String.swapcase(x)`

文字を大文字に、小文字に、先頭だけ大文字で残りを小文字に、各文字の大小を入れ替えた新しい String。大小の対応は Ruby と同じく Unicode のものです（`"straße"` の upcase は `"STRASSE"`）。

```ruby
p(String.upcase("abc"))          # => "ABC"
p(String.downcase("ABC"))        # => "abc"
p(String.capitalize("hELLO"))    # => "Hello"
p(String.swapcase("Ab"))         # => "aB"
p(String.upcase("straße"))       # => "STRASSE"
```

## upcase!, downcase!, capitalize!, swapcase!

`String.upcase!(x)`

`String.downcase!(x)`

`String.capitalize!(x)`

`String.swapcase!(x)`

同じ変換を**その場で**行います。変わったときは主語を、すでにその形だったときは nil を返します。その結果を検査せずに使うことは `--strict` レベル 2 で `nil` の問題です。

```ruby
s = "Hello"
p(String.upcase!(s))         # => "HELLO"
p(s)                         # => "HELLO"
p(String.upcase!(s))         # => nil
p(String.capitalize!("Abc")) # => nil
```

```ruby error
s = "Hello"
r = String.upcase!(s)
p(String.size(r))            # !> argument 1 may be nil
```

## strip, lstrip, rstrip

`String.strip(x)`

`String.lstrip(x)`

`String.rstrip(x)`

先頭と末尾の空白（`strip`）、先頭だけ（`lstrip`）、末尾だけ（`rstrip`）を除いた新しい String。空白は Ruby と同じく、空白文字、タブ、改行、NUL です。

```ruby
p(String.strip("  a  "))     # => "a"
p(String.lstrip("  a  "))    # => "a  "
p(String.rstrip("  a  "))    # => "  a"
```

## strip!, lstrip!, rstrip!

`String.strip!(x)`

`String.lstrip!(x)`

`String.rstrip!(x)`

同じことを**その場で**行います。何か取り除いたときは主語、取り除くものが無かったときは nil（検査せずに使うと `--strict` レベル 2 で `nil` の問題）。

```ruby
s = "  a  "
p(String.strip!(s))          # => "a"
p(String.strip!(s))          # => nil
p(String.lstrip!("a"))       # => nil
```

## chomp

`String.chomp(x, [String])`

末尾の行末 1 つ（`"\n"`、`"\r\n"`、`"\r"`）を除いた新しい String。行末が無ければそのままの複製です。`suffix` を渡すと代わりにその接尾辞を除きます（Ruby と同じく、`""` は末尾の改行をすべて除きます）。

```ruby
p(String.chomp("a\n"))       # => "a"
p(String.chomp("a\r\n"))     # => "a"
p(String.chomp("a"))         # => "a"
p(String.chomp("abc!", "!"))         # => "abc"
p(String.chomp("abc", "x"))          # => "abc"
p(String.chomp("abc\n\n", ""))       # => "abc"
```

## chomp!

`String.chomp!(x, [String])`

末尾の行末 1 つを**その場で**除きます。`suffix` を渡すとその接尾辞を除きます。何か除いたときは主語、除くものが無かったときは nil（検査せずに使うと `--strict` レベル 2 で `nil` の問題）。

```ruby
s = "a\n"
p(String.chomp!(s))          # => "a"
p(String.chomp!(s))          # => nil
p(String.chomp!("abc", "bc"))        # => "a"
p(String.chomp!("abc", "x"))         # => nil
```

```ruby error
p(String.chomp!("abc") + "!")        # !> the operands may be nil
```

## chop

`String.chop(x)`

最後の文字を除いた新しい String（`"\r\n"` は 1 文字と数えます）。`""` は `""` です。

```ruby
p(String.chop("abc"))        # => "ab"
p(String.chop("a\r\n"))      # => "a"
p(String.chop(""))           # => ""
```

## chop!

`String.chop!(x)`

最後の文字を**その場で**除きます。主語を返し、空だったときは nil（検査せずに使うと `--strict` レベル 2 で `nil` の問題）。

```ruby
s = "abc"
p(String.chop!(s))           # => "ab"
p(String.chop!(""))          # => nil
```

## chr

`String.chr(x)`

先頭の文字を String で返します。空の String なら `""`（Ruby の `chr`）。

```ruby
p(String.chr("abc"))         # => "a"
p(String.chr(""))            # => ""
```

## delete_prefix, delete_suffix

`String.delete_prefix(x, String)`

`String.delete_suffix(x, String)`

先頭の `prefix`、末尾の `suffix` を除いた新しい String。それで始まって（終わって）いなければ、そのままの複製です。

```ruby
p(String.delete_prefix("foobar", "foo"))   # => "bar"
p(String.delete_suffix("foobar", "bar"))   # => "foo"
p(String.delete_prefix("foobar", "x"))     # => "foobar"
```

## delete_prefix!, delete_suffix!

`String.delete_prefix!(x, String)`

`String.delete_suffix!(x, String)`

同じことを**その場で**行います。接頭辞（接尾辞）があって除いたときは主語、無かったときは nil（検査せずに使うと `--strict` レベル 2 で `nil` の問題）。

```ruby
s = "foobar"
p(String.delete_prefix!(s, "foo"))   # => "bar"
p(String.delete_prefix!(s, "foo"))   # => nil
p(String.delete_suffix!(s, "ar"))    # => "b"
p(s)                                 # => "b"
```

## include?, start_with?, end_with?

`String.include?(x, String)`

`String.start_with?(x, String)`

`String.end_with?(x, String)`

`t` が現れるとき、`t` で始まるとき、`t` で終わるとき true。どれも String をちょうど 1 つ取ります（Ruby の `start_with?` は複数の引数や Regexp も取ります）。

```ruby
s = "hello world"
p(String.include?(s, "wor"))     # => true
p(String.start_with?(s, "he"))   # => true
p(String.end_with?(s, "x"))      # => false
```

## index

`String.index(x, String|Regexp, [Integer])`

String `t` の最初の出現、または Regexp の最初の一致の、位置 `pos`（既定 0。負の値は末尾から）以降での文字位置（Integer）。無ければ nil で、検査せずに使うことは `--strict` レベル 2 で `nil` の問題です。`""` は `pos` で見つかります。

```ruby
s = "hello world"
p(String.index(s, "o"))          # => 4
p(String.index(s, "o", 5))       # => 7
p(String.index(s, /w./))         # => 6
p(String.index(s, "l", -3))      # => 9
p(String.index(s, "z"))          # => nil
```

```ruby error
s = "hello"
i = String.index(s, "o")
p(i + 1)                         # !> the operands may be nil
```

## rindex

`String.rindex(x, String|Regexp, [Integer])`

`pos`（既定: 末尾）以前に始まる、`t` の最後の出現（Regexp なら最後の一致）の位置。無ければ nil（検査せずに使うと `--strict` レベル 2 で `nil` の問題）。

```ruby
s = "hello world"
p(String.rindex(s, "o"))         # => 7
p(String.rindex(s, "o", 5))      # => 4
p(String.rindex(s, "z"))         # => nil
```

```ruby error
p(String.rindex("abc", "b") + 1) # !> the operands may be nil
```

## byteindex

`String.byteindex(x, String|Regexp, [Integer])`

`index` と同じですが、結果と `pos` は**バイト**位置です。出現が無ければ nil（検査せずに使うと `--strict` レベル 2 で `nil` の問題）。`pos` は文字の境界になければならず、多バイト文字の途中の位置は `IndexError`（`offset 2 does not land on character boundary`）で、rescue できます。

```ruby
p(String.index("héllo", "l"))        # => 2
p(String.byteindex("héllo", "l"))    # => 3
p(String.byteindex("héllo", "z"))    # => nil
p(String.byteindex("héllo", "l", 3)) # => 3
```

```ruby error
p(String.byteindex("héllo", "l", 2))   # !> IndexError: String.byteindex: offset 2 does not land on character boundary
```

## byterindex

`String.byterindex(x, String|Regexp, [Integer])`

`rindex` のバイト位置版: バイト位置 `pos` 以前に始まる最後の出現。無ければ nil（検査せずに使うと `--strict` レベル 2 で `nil` の問題）。

```ruby
p(String.byterindex("héllo", "l"))      # => 4
p(String.byterindex("héllo", "l", 3))   # => 3
```

```ruby error
p(String.byterindex("abc", "b") + 1)    # !> the operands may be nil
```

## match

`String.match(x, String|Regexp, [Integer])`

位置 `pos`（既定 0）以降で Regexp が最初に一致したところの `MatchData`。一致しなければ nil で、結果を検査せずに使うこと（`if m` 無しの `m[1]`）は `--strict` レベル 2 で `nil` の問題です。String のパターンは Ruby と同じく Regexp として解釈されます（`"."` は任意の 1 文字。`"+"` のような不正なパターンは `RegexpError` で、rescue できます）。`$~` や `$1` は無く、グループは MatchData から `m[0]`、`m[1]`、`m["name"]` で読みます。

```ruby
m = String.match("hello world", /(w)(o)/)
if m
  p(m[0])                      # => "wo"
  p(m[2])                      # => "o"
end
p(String.match("hello", "zzz"))      # => nil
```

```ruby error
p(String.match("a+c", "+"))  # !> RegexpError: String.match: target of repeat operator is not specified: /+/
```

```ruby error
m = String.match("abc", /b/)
p(m[0])                      # !> the operands may be nil (MatchData | nil)
```

## match?

`String.match?(x, String|Regexp, [Integer])`

位置 `pos`（既定 0）以降でパターンが一致するとき true。MatchData は作りません。String のパターンは Regexp として解釈され、不正なパターンは `match` と同じく `RegexpError` です。

```ruby
p(String.match?("hello", /l+/))      # => true
p(String.match?("hello", "o", 8))    # => false
p(String.match?("abc", "b."))        # => true
begin
  p(String.match?("a+c", "+"))
rescue RegexpError => e
  puts(Exception.message(e))         # => target of repeat operator is not specified: /+/
end
```

## scan

`String.scan(x, String|Regexp)`

重ならないすべての一致を左から順に Array で返します。グループが無ければ一致した String の Array。グループがあれば、グループごとに 1 つの String を持つ **Tuple** の Array です（Ruby は Array）。一致に関与しなかったグループはその位置が nil で、これは「外れの nil」（`index-nil`、レベル 3）です。

```ruby
p(String.scan("a1b22", /\d+/))       # => ["1", "22"]
p(String.scan("abab", "ab"))         # => ["ab", "ab"]
p(String.scan("a1b22", /(\w)(\d)/))  # => [["a", "1"], ["b", "2"]]
p(String.scan("a1 b", /(\w)(\d)?/))  # => [["a", "1"], ["b", nil]]
```

## count

`String.count(x, String)`

集合 `chars` に属する文字の個数（Integer）。集合は Ruby の `tr` の書き方です: `"lo"` は文字の列挙、`"a-z"` は範囲、先頭の `^` は否定。集合は 1 つだけです（Ruby は複数の積を取ります）。`"z-a"` のような逆順の範囲は `ArgumentError`（`invalid range "z-a" in string transliteration`）で、`tr`、`delete`、`squeeze` でも同じです。

```ruby
s = "hello world"
p(String.count(s, "lo"))     # => 5
p(String.count(s, "a-z"))    # => 10
p(String.count(s, "^l"))     # => 8
```

```ruby error
p(String.count("abc", "z-a"))    # !> ArgumentError: String.count: invalid range "z-a" in string transliteration
```

## partition, rpartition

`String.partition(x, String|Regexp)`

`String.rpartition(x, String|Regexp)`

`sep`（String か Regexp）の最初（`partition`）または最後（`rpartition`）の出現で分け、**Tuple** `[前, 区切り, 後]` を返します（Ruby は Array）。`sep` が現れないとき、`partition` は `[s, "", ""]`、`rpartition` は `["", "", s]` です。

```ruby
p(String.partition("a=b=c", "="))    # => ["a", "=", "b=c"]
p(String.rpartition("a=b=c", "="))   # => ["a=b", "=", "c"]
p(String.partition("hello", /l+/))   # => ["he", "ll", "o"]
p(String.partition("abc", "x"))      # => ["abc", "", ""]
p(String.rpartition("abc", "x"))     # => ["", "", "abc"]
```

## sub, gsub

`String.sub(x, String|Regexp, [String|Hash]) [{ }]`

`String.gsub(x, String|Regexp, [String|Hash]) [{ }]`

`pattern` の最初の一致（`sub`）またはすべての一致（`gsub`）を置き換えた新しい String。String のパターンは文字どおりに一致します（`"."` はピリオドで、任意の文字ではありません）。置換は 3 つの形のどれかです: **String**（`\0` が一致全体、`\1` が最初のグループ、`\k<name>` が名前付きグループ）、**Hash**（キーが一致した String、値を `to_s` で表示したものが置換。キーに無い一致は取り除かれる）、**ブロック**（一致した String を受け取り（MatchData ではありません）、その結果を `to_s` で表示したものが置換）。置換もブロックも無いと実行時に `ArgumentError` です（Ruby の Enumerator を返す形はありません）。

```ruby
s = "hello"
p(String.sub(s, "l", "L"))                 # => "heLlo"
p(String.gsub(s, "l", "L"))                # => "heLLo"
p(String.gsub(s, /l+/, "<\\0>"))           # => "he<ll>o"
p(String.gsub(s, /(l)(o)/, "\\2\\1"))      # => "helol"
p(String.gsub(s, /[el]/, Hash["e" => "3", "l" => 1]))   # => "h311o"
p(String.gsub(s, /l/) { |m| String.upcase(m) })         # => "heLLo"
p(String.sub(s, /l/) { |m| 7 })            # => "he7lo"
p(s)                                       # => "hello"
```

```ruby error
p(String.sub("abc", "b"))    # !> ArgumentError: String.sub: sub needs a replacement or a block
```

## sub!, gsub!

`String.sub!(x, String|Regexp, [String|Hash]) [{ }]`

`String.gsub!(x, String|Regexp, [String|Hash]) [{ }]`

同じ置換を**その場で**行います。何か置き換えたときは主語、パターンが一致しなかったときは nil（主語は変わりません）を返し、結果を検査せずに使うことは `--strict` レベル 2 で `nil` の問題です。置換の形は `sub`、`gsub` と同じです。

```ruby
s = "hello"
p(String.sub!(s, "l", "L"))      # => "heLlo"
p(s)                             # => "heLlo"
p(String.gsub!(s, "zz", "y"))    # => nil
String.gsub!(s, /l/i) { |m| "_" }
p(s)                             # => "he__o"
```

```ruby error
s = "hello"
p(String.sub!(s, "x", "y") + "!")    # !> the operands may be nil
```

## tr

`String.tr(x, String, String)`

集合 `from` の各文字を、`to` の同じ位置の文字で置き換えた新しい String（Ruby の `tr`）。`"a-y"` は範囲、`from` の先頭の `^` は否定、`from` より短い `to` は最後の文字を繰り返し、空の `to` は削除です。逆順の範囲は `ArgumentError`（`invalid range "z-a" in string transliteration`）です。

```ruby
p(String.tr("hello", "el", "ip"))    # => "hippo"
p(String.tr("hello", "a-y", "b-z"))  # => "ifmmp"
p(String.tr("hello", "^l", "*"))     # => "**ll*"
p(String.tr("hello", "lo", ""))      # => "he"
```

```ruby error
p(String.tr("abc", "z-a", "x"))      # !> ArgumentError: String.tr: invalid range "z-a" in string transliteration
```

## tr!

`String.tr!(x, String, String)`

`tr` を**その場で**行います。何か変わったときは主語、変わらなければ nil（検査せずに使うと `--strict` レベル 2 で `nil` の問題）。

```ruby
s = "hello"
p(String.tr!(s, "l", "L"))   # => "heLLo"
p(String.tr!(s, "z", "Z"))   # => nil
```

## tr_s

`String.tr_s(x, String, String)`

`tr` と同じ置き換えをしてから、置き換えた文字の連続を 1 つに縮めます（Ruby の `tr_s`）。

```ruby
p(String.tr_s("hello", "l", "r"))      # => "hero"
p(String.tr_s("aabbcc", "a-c", "x"))   # => "x"
```

## tr_s!

`String.tr_s!(x, String, String)`

`tr_s` を**その場で**行います。何か変わったときは主語、変わらなければ nil（検査せずに使うと `--strict` レベル 2 で `nil` の問題）。

```ruby
s = "aabb"
p(String.tr_s!(s, "a", "x"))     # => "xbb"
p(String.tr_s!(s, "z", "x"))     # => nil
```

## delete

`String.delete(x, String, *String)`

渡したすべての集合（`tr` の書き方: `"a-k"`、`"^l"`）に属する文字を除いた新しい String。複数の集合は Ruby と同じく積です: `delete("hello", "l", "o")` は両方の集合に属する文字が無いので何も除きません。逆順の範囲は `ArgumentError` です。

```ruby
p(String.delete("hello", "l"))     # => "heo"
p(String.delete("hello", "a-k"))   # => "llo"
p(String.delete("hello", "^l"))    # => "ll"
p(String.delete("hello", "l", "o"))        # => "hello"
p(String.delete("hello", "a-z", "^l"))     # => "ll"
```

## delete!

`String.delete!(x, String, *String)`

渡したすべての集合に属する文字を**その場で**削除します（複数の集合は Ruby と同じく積）。何か削除したときは主語、しなかったときは nil（検査せずに使うと `--strict` レベル 2 で `nil` の問題）。

```ruby
s = "hello"
p(String.delete!(s, "l"))              # => "heo"
p(String.delete!(s, "z"))              # => nil
p(String.delete!("hello", "l", "^l"))  # => nil
```

```ruby error
p(String.delete!("a", "z-a"))          # !> ArgumentError: String.delete!: invalid range "z-a"
```

## squeeze

`String.squeeze(x, *String)`

同じ文字の連続を 1 つに縮めた新しい String。集合を渡すと、そのすべてに属する文字の連続だけを縮めます（複数の集合は Ruby と同じく積）。

```ruby
p(String.squeeze("aaabbb  c"))         # => "ab c"
p(String.squeeze("aaabbb  c", "a"))    # => "abbb  c"
p(String.squeeze("aaabbb  c", "a-b"))  # => "ab  c"
p(String.squeeze("aaabbb  c", "a-b", "b"))     # => "aaab  c"
```

## squeeze!

`String.squeeze!(x, *String)`

`squeeze` を**その場で**行います。集合はいくつでも渡せます（Ruby と同じく積）。何か変わったときは主語、変わらなければ nil（検査せずに使うと `--strict` レベル 2 で `nil` の問題）。

```ruby
s = "aaabbb"
p(String.squeeze!(s))                # => "ab"
p(String.squeeze!(s))                # => nil
p(String.squeeze!("aabb", "a"))      # => "abb"
```

## split

`String.split(x, [String|Regexp], [Integer])`

String の Array に分けます。`sep` 無しか `" "` なら空白の連続で分け、先頭の空白は無視します（awk 流）。他の String ならその各出現で、`""` なら 1 文字ずつ、Regexp なら各一致で分け、Regexp のグループは結果に含まれます（Ruby の規則）。`limit`（既定 0）は個数の上限です: 正なら最大その個数で最後の要素に残りが入り、0 なら末尾の空文字列を落とし、負なら残します。ブロックの形はありません。

```ruby
p(String.split("a b  c"))              # => ["a", "b", "c"]
p(String.split("a,b,,c", ","))         # => ["a", "b", "", "c"]
p(String.split("a,b,,c", ",", 2))      # => ["a", "b,,c"]
p(String.split("a,b,,", ","))          # => ["a", "b"]
p(String.split("a,b,,", ",", -1))      # => ["a", "b", "", ""]
p(String.split("a1b2c", /\d/))         # => ["a", "b", "c"]
p(String.split("a1b", /(\d)/))         # => ["a", "1", "b"]
p(String.split("abc", ""))             # => ["a", "b", "c"]
p(String.split("", ","))               # => []
```

## chars

`String.chars(x)`

文字の Array。各要素は 1 文字の String です。

```ruby
p(String.chars("aé"))        # => ["a", "é"]
p(String.chars(""))          # => []
```

## lines

`String.lines(x)`

行の Array。各行は `"\n"` を保ちます（最後の行には無いことがあります）。

```ruby
p(String.lines("a\nb\n"))    # => ["a\n", "b\n"]
p(String.lines("a\nb"))      # => ["a\n", "b"]
p(String.lines(""))          # => []
```

## bytes

`String.bytes(x)`

バイトの Array（0..255 の Integer）。

```ruby
p(String.bytes("aé"))        # => [97, 195, 169]
```

## codepoints

`String.codepoints(x)`

Unicode のコードポイントの Array（Integer）。

```ruby
p(String.codepoints("aé"))   # => [97, 233]
```

## grapheme_clusters

`String.grapheme_clusters(x)`

グラフェムクラスタ（読む人が 1 文字と見るもの: 基底文字と結合文字の組）の Array。各要素は String です。

```ruby
s = "éa"
p(String.length(s))                  # => 3
p(Array.size(String.grapheme_clusters(s)))                       # => 2
p(Array.map(String.grapheme_clusters(s)) { |g| String.length(g) })   # => [2, 1]
```

## each_char

`String.each_char(x) { }`

各文字（1 文字の String）を順にブロックに渡し、主語を返します。ブロックは必須で、無いと静的な誤りです（Ruby の Enumerator を返す形はありません）。

```ruby
r = String.each_char("ab") { |c| p(c) }
# => "a"
# => "b"
p(r)                         # => "ab"
```

```ruby error
String.each_char("ab")       # !> String.each_char requires a block
```

## each_line

`String.each_line(x) { }`

各行を `"\n"` を保ったままブロックに渡し、主語を返します。ブロックは必須です。区切りの引数はありません（Ruby の `each_line(sep)`）。

```ruby
String.each_line("a\nb") { |l| p(l) }
# => "a\n"
# => "b"
```

## each_byte

`String.each_byte(x) { }`

各バイト（Integer）をブロックに渡し、主語を返します。ブロックは必須です。

```ruby
String.each_byte("aé") { |b| p(b) }
# => 97
# => 195
# => 169
```

## each_codepoint

`String.each_codepoint(x) { }`

各コードポイント（Integer）をブロックに渡し、主語を返します。ブロックは必須です。

```ruby
String.each_codepoint("aé") { |c| p(c) }
# => 97
# => 233
```

## each_grapheme_cluster

`String.each_grapheme_cluster(x) { }`

各グラフェムクラスタ（String）をブロックに渡し、主語を返します。ブロックは必須です。

```ruby
String.each_grapheme_cluster("éa") { |g| p(String.length(g)) }
# => 2
# => 1
```

## upto

`String.upto(x, String) { }`

`x`、その `String.succ`、…と `last` まで（`last` を含む）をブロックに渡します。Ruby の `upto`（`"a".upto("e")`）と同じ規則で、値が `last` より長くなったところで止まるので、`x` がすでに `last` を越えていれば何も渡しません。数字だけの String は数として進みます（`"9"` から `"11"`）。主語を返します。

```ruby
String.upto("a", "c") { |s| p(s) }
# => "a"
# => "b"
# => "c"
String.upto("az", "bb") { |s| p(s) }
# => "az"
# => "ba"
# => "bb"
String.upto("9", "11") { |s| p(s) }
# => "9"
# => "10"
# => "11"
String.upto("b", "a") { |s| p(s) }
```

## succ, next

`String.succ(x)`

`String.next(x)`

Ruby の意味で `x` の「次」の新しい String: 右端の英字または数字を 1 つ進め、桁あふれは左へ繰り上げます（`"az"` は `"ba"`、`"a9"` は `"b0"`、`"Zz"` は `"AAa"`）。`""` は `""` です。

```ruby
p(String.succ("az"))         # => "ba"
p(String.next("Zz"))         # => "AAa"
p(String.succ("a9"))         # => "b0"
p(String.succ(""))           # => ""
```

## succ!, next!

`String.succ!(x)`

`String.next!(x)`

主語を**その場で**その「次」に置き換え、主語を返します（nil にはなりません）。

```ruby
s = "az"
p(String.succ!(s))           # => "ba"
p(String.next!(s))           # => "bb"
p(s)                         # => "bb"
```

## reverse

`String.reverse(x)`

文字の順を逆にした新しい String。

```ruby
p(String.reverse("abc"))     # => "cba"
```

## reverse!

`String.reverse!(x)`

主語を**その場で**逆順にし、主語を返します（nil にはなりません）。

```ruby
s = "abc"
p(String.reverse!(s))        # => "cba"
p(s)                         # => "cba"
```

## ljust, rjust, center

`String.ljust(x, Integer, [String])`

`String.rjust(x, Integer, [String])`

`String.center(x, Integer, [String])`

`width` 文字の新しい String: 主語の右（`ljust`）、左（`rjust`）、両側（`center`。余りは右）に `pad`（既定 `" "`）の繰り返しを、幅に合わせて切って詰めます。`width` が長さ以下なら、そのままの複製です。空の `pad` は `ArgumentError`（`zero width padding`）です。

```ruby
p(String.ljust("ab", 5))         # => "ab   "
p(String.rjust("ab", 5, "0"))    # => "000ab"
p(String.center("ab", 6, "*"))   # => "**ab**"
p(String.ljust("ab", 5, "xy"))   # => "abxyx"
p(String.center("ab", 1))        # => "ab"
```

```ruby error
p(String.ljust("a", 3, ""))      # !> ArgumentError: String.ljust: zero width padding
```

## to_s

`String.to_s(x)`

その String 自身。どの型にも `T.to_s(x)` と書けるようにあります。

```ruby
p(String.to_s("x"))          # => "x"
```

## to_i

`String.to_i(x, [Integer])`

String の先頭に書かれた Integer を基数 `base`（2..36、既定 10）で読みます。Ruby の `to_i` と同じく、先頭の空白、符号、数字の間の下線を許し、それ以外の文字で読むのをやめ、数字が無ければ 0 です（誤りにはなりません。[組み込みの操作](../09-builtins.md)の `Integer(s)` は代わりに例外を投げます）。基数 0 は接頭辞を読みます: `0x`（16）、`0b`（2）、`0o` または先頭の `0`（8）。基数 16 では `0x` の接頭辞を許します。2..36 の外の基数（0 以外）は `ArgumentError` です。

```ruby
p(String.to_i("42"))         # => 42
p(String.to_i("  -12abc"))   # => -12
p(String.to_i("abc"))        # => 0
p(String.to_i("ff", 16))     # => 255
p(String.to_i("0x1f", 16))   # => 31
p(String.to_i("0b101", 0))   # => 5
p(String.to_i("012", 0))     # => 10
p(String.to_i("z", 36))      # => 35
```

```ruby error
p(String.to_i("1", 37))      # !> ArgumentError: String.to_i: invalid radix 37
```

## to_f

`String.to_f(x)`

String の先頭に書かれた Float（`"3.5e2"`。下線を許します）。無ければ 0.0 です（誤りにはなりません。`Float(s)` は例外を投げます）。Float に収まらない値は `Infinity` です。

```ruby
p(String.to_f("3.5e2"))      # => 350.0
p(String.to_f("1_000.5"))    # => 1000.5
p(String.to_f("abc"))        # => 0.0
```

## to_r

`String.to_r(x)`

String の先頭に書かれた Rational: `"3/4"`、`"0.75"`、`"1e2"`。数が無ければ `(0/1)` です。

```ruby
p(String.to_r("3/4"))        # => (3/4)
p(String.to_r("0.75"))       # => (3/4)
p(String.to_r("abc"))        # => (0/1)
```

## to_c

`String.to_c(x)`

String の先頭に書かれた Complex（`"1+2i"`）。無ければ `(0+0i)` です。

```ruby
p(String.to_c("1+2i"))       # => (1+2i)
p(String.to_c("x"))          # => (0+0i)
```

## to_sym, intern

`String.to_sym(x)`

`String.intern(x)`

その名前の Symbol。どんな String も Symbol になれ、識別子でないものは引用符付きで表示されます。

```ruby
p(String.to_sym("abc"))      # => :abc
p(String.intern("a b"))      # => :"a b"
```

## hex

`String.hex(x)`

String を 16 進の Integer として読みます（Ruby の `hex`）。符号と `0x` の接頭辞を許し、16 進数字でない文字で読むのをやめ、数字が無ければ 0 です。

```ruby
p(String.hex("ff"))          # => 255
p(String.hex("0x1F"))        # => 31
p(String.hex("-a"))          # => -10
p(String.hex("zz"))          # => 0
```

## oct

`String.oct(x)`

String を 8 進の Integer として読みます（Ruby の `oct`）。接頭辞 `0x`、`0b`、`0o` があれば Ruby と同じく基数が変わります。数字が無ければ 0 です。

```ruby
p(String.oct("17"))          # => 15
p(String.oct("0x1f"))        # => 31
p(String.oct("0b11"))        # => 3
p(String.oct("9"))           # => 0
```

## ord

`String.ord(x)`

先頭の文字のコードポイント（Integer）。空の String は `ArgumentError` です。

```ruby
p(String.ord("a"))           # => 97
p(String.ord("é"))           # => 233
```

```ruby error
p(String.ord(""))            # !> ArgumentError: String.ord: empty string
```

## sum

`String.sum(x, [Integer])`

バイトの和を 2 の `bits` 乗（既定 16）で割った余り。Ruby の簡単なチェックサムです。

```ruby
p(String.sum("abc"))         # => 294
p(String.sum("abc", 8))      # => 38
```

## crypt

`String.crypt(x, String)`

システムの `crypt(3)` による、`salt` を使った String の一方向ハッシュ（Ruby と同じ）。2 バイトより短い salt は `ArgumentError` です。結果はプラットフォームの libc に依存します。

```ruby
p(String.size(String.crypt("abc", "ab")) > 2)   # => true
```

```ruby error
p(String.crypt("abc", "a"))  # !> ArgumentError: String.crypt: salt too short (need >=2 bytes)
```

## concat

`String.concat(x, *String|Integer)`

各引数を主語の末尾に**その場で**追加し、主語を返します。Integer はそのコードポイントの文字として追加されます。

```ruby
s = "a"
p(String.concat(s, "b", 99, "d"))    # => "abcd"
p(s)                                 # => "abcd"
```

## append_as_bytes

`String.append_as_bytes(x, *String|Integer)`

各 String 引数の**バイト列**を、Integer は 1 バイト（下位 8 ビット）として、エンコーディングの変換も妥当性の検査も無しに**その場で**追加します（Ruby と同じ）。結果は不正な String になりえます。主語を返します。

```ruby
s = "a"
p(String.append_as_bytes(s, "é", 255))   # => "aé\xFF"
p(String.bytesize(s))                    # => 4
p(String.valid_encoding?(s))             # => false
```

## prepend

`String.prepend(x, *String)`

引数を順に主語の先頭に**その場で**挿入し、主語を返します。

```ruby
s = "c"
p(String.prepend(s, "a", "b"))   # => "abc"
p(s)                             # => "abc"
```

## insert

`String.insert(x, Integer, String)`

位置 `i` の文字の前に `str` を**その場で**挿入します。負の `i` は末尾から数えた文字の後に挿入するので、-1 は末尾への追加です。主語を返します。範囲外の位置は `IndexError` です。

```ruby
s = "ac"
p(String.insert(s, 1, "b"))      # => "abc"
p(String.insert(s, -1, "d"))     # => "abcd"
p(String.insert(s, 0, "_"))      # => "_abcd"
```

```ruby error
p(String.insert("abc", 10, "x")) # !> IndexError: String.insert: index 10 out of string
```

## replace

`String.replace(x, String)`

主語の内容を `str` の内容で**その場で**置き換え、主語を返します。主語を持つすべての変数から新しい内容が見えます。

```ruby
s = "old"
t = s
String.replace(s, "new")
p(t)                         # => "new"
```

## clear

`String.clear(x)`

すべての文字を**その場で**取り除き、主語（`""` になっています）を返します。

```ruby
s = "hello"
p(String.clear(s))           # => ""
p(String.empty?(s))          # => true
```

## encoding

`String.encoding(x)`

その String のエンコーディングの名前を String で返します（`"UTF-8"`、`"ASCII-8BIT"`、...）。Ruby は Encoding オブジェクトを返しますが、Sake にその型はありません。

```ruby
p(String.encoding("é"))              # => "UTF-8"
p(String.encoding(String.b("é")))    # => "ASCII-8BIT"
```

## force_encoding

`String.force_encoding(x, String)`

主語のバイト列にエンコーディング `enc` のラベルを**その場で**付け替え、主語を返します（Ruby の `force_encoding` と同じ）。バイト列は変換されず、新しいエンコーディングで妥当かは `valid_encoding?` で分かります。未知のエンコーディング名は `ArgumentError`、変えられない String（Hash のキー、Symbol の名前など）は `TypeError` です。

```ruby
s = String.b("\xC3\xA9")
p(String.encoding(s))                # => "ASCII-8BIT"
t = String.force_encoding(s, "UTF-8")
p(String.encoding(s))                # => "UTF-8"
p(Kernel.equal?(s, t))               # => true
p(s)                                 # => "é"
p(String.valid_encoding?(String.force_encoding("\xff", "UTF-8")))   # => false
```

```ruby error
p(String.force_encoding("a", "bogus"))   # !> ArgumentError: String.force_encoding: unknown encoding name - bogus
```

## encode

`String.encode(x, String, [String])`

文字をエンコーディング `to` に変換した新しい String。`from`（既定: 主語のエンコーディング）はバイト列の読み方を指定します。`to` で表せない文字、主語の不正なバイト、未知のエンコーディング名は `EncodingError` です。

```ruby
u = String.encode("é", "UTF-16LE")
p(String.encoding(u))                            # => "UTF-16LE"
p(String.bytesize(u))                            # => 2
p(String.encode("\xE9", "UTF-8", "ISO-8859-1"))  # => "é"
begin
  String.encode("é", "US-ASCII")
rescue EncodingError => e
  p(Exception.message(e))                        # => "U+00E9 from UTF-8 to US-ASCII"
end
```

## valid_encoding?

`String.valid_encoding?(x)`

バイト列がその String のエンコーディングで妥当なとき true。

```ruby
p(String.valid_encoding?("é"))       # => true
p(String.valid_encoding?("\xff"))    # => false
```

## ascii_only?

`String.ascii_only?(x)`

すべての文字が ASCII のとき true（空の String も true）。

```ruby
p(String.ascii_only?("abc"))         # => true
p(String.ascii_only?("é"))           # => false
```

## b

`String.b(x)`

同じバイト列に `ASCII-8BIT`（バイナリ）のラベルを付けた複製。長さはバイト数になります。

```ruby
b = String.b("é")
p(b)                         # => "\xC3\xA9"
p(String.length(b))          # => 2
```

## scrub

`String.scrub(x, [String])`

不正なバイト列をすべて `repl`（既定: 置換文字 `"�"`）で置き換えた新しい String。

```ruby
p(String.scrub("a\xffb", "?"))       # => "a?b"
p(String.valid_encoding?(String.scrub("a\xffb")))   # => true
```

## scrub!

`String.scrub!(x, [String])`

`scrub` を**その場で**行います。置き換えるものが無かったときも主語を返します（他の `!` 形と違い、Ruby と同じく nil にはなりません）。

```ruby
s = "a\xffb"
p(String.scrub!(s, "!"))     # => "a!b"
p(String.scrub!("ok"))       # => "ok"
```

## unicode_normalize

`String.unicode_normalize(x, [Symbol])`

Unicode 正規化形 `form` にした新しい String: `:nfc`（既定）、`:nfd`、`:nfkc`、`:nfkd`。他の Symbol は `ArgumentError`、Unicode でないエンコーディングの String（バイナリの String）は `EncodingError` です。

```ruby
d = String.unicode_normalize("é", :nfd)
p(String.length(d))                          # => 2
p(String.length(String.unicode_normalize(d)))   # => 1
```

```ruby error
p(String.unicode_normalize("a", :bogus))     # !> ArgumentError: String.unicode_normalize: Invalid normalization form bogus
```

## unicode_normalize!

`String.unicode_normalize!(x, [Symbol])`

`unicode_normalize` を**その場で**行い、主語を返します（nil にはなりません）。

```ruby
s = "é"
p(String.unicode_normalize!(s))      # => "é"
p(String.length(s))                  # => 1
```

## unicode_normalized?

`String.unicode_normalized?(x, [Symbol])`

String がすでに形 `form`（既定 `:nfc`）になっているとき true。

```ruby
p(String.unicode_normalized?("é"))           # => true
p(String.unicode_normalized?("é", :nfd))     # => false
```

## dump

`String.dump(x)`

主語を引用符で囲んだ ASCII だけのソース形にした新しい String: 印字できない文字と非 ASCII 文字は `\n` や `é` のようなエスケープになり、`"` と `\` はエスケープされます。`undump` が元に戻します。

```ruby
p(String.dump("a\né"))  # => "\"a\\n\\u00E9\""
```

## undump

`String.undump(x)`

`dump` が主語を作った元の String: 引用符を外し、エスケープを読みます。`dump` の形でない String は Ruby のメッセージを持つ `ArgumentError` です（Ruby のメソッドは RuntimeError を投げますが、Sake の RuntimeError は `raise "msg"` と `Thread.raise` からしか生まれません）。

```ruby
p(String.undump("\"a\\n\""))         # => "a\n"
p(String.undump(String.dump("é")))   # => "é"
begin
  p(String.undump("abc"))
rescue ArgumentError => e
  puts(Exception.message(e))         # => invalid dumped string; not wrapped with '"' nor '"...".force_encoding("...")' form
end
```

```ruby error
p(String.undump("abc"))      # !> ArgumentError: String.undump: invalid dumped string
```

## unpack

`String.unpack(x, String)`

バイト列を `Array.pack` の書式 `fmt` に従って Array に復号します（Ruby の `unpack`）: `C` は符号無しバイト、`v` はリトルエンディアンの 16 ビット Integer、`e` はリトルエンディアンの Float、`a`/`A`/`Z` は String、`*` は繰り返し。要素の型は指示子に従います（Integer、String、Float）。バイトが残っていない指示子は nil を与えます。未知の指示子は `ArgumentError` です。

```ruby
p(String.unpack("AB", "C*"))             # => [65, 66]
p(String.unpack("\x01\x00", "v"))        # => [1]
p(String.unpack("ab", "a1a1"))           # => ["a", "b"]
p(String.unpack("\x00\x00\x80\x3f", "e"))   # => [1.0]
p(String.unpack("", "C"))                # => [nil]
```

```ruby error
p(String.unpack("abc", "Z%"))            # !> ArgumentError: String.unpack: % is not supported
```

## unpack1

`String.unpack1(x, String)`

`unpack(x, fmt)` の最初の要素。そのためのバイトが無ければ nil で、結果を検査せずに使うことは `--strict` レベル 2 で `nil` の問題です。

```ruby
p(String.unpack1("\x01\x00", "v"))   # => 1
p(String.unpack1("abc", "a*"))       # => "abc"
p(String.unpack1("", "C"))           # => nil
```

```ruby error
p(String.unpack1("ab", "C") + 1)     # !> the operands may be nil
```
