# ENV

ENV はプロセスの環境変数を読み書きする操作の集まりです。Ruby の `ENV["X"]` は `ENV.get("X")`、`ENV["X"] = v` は `ENV.set("X", v)` と書きます（Sake では `ENV` は値ではなく、添字を付けられません。[組み込み](../09-builtins.md)）。名前も値も String です。

変更はこのプロセスと、以後に `Open3` や `Kernel.system` で起こす子プロセスに見えます。`ENV.to_h` は写しで、変えても環境は変わりません。

ENV に演算子はありません。例は `SAKE_DOC_` で始まる名前を使い、終わりに消します。

## get

`ENV.get(String)`

変数の値（String）、設定されていなければ nil です（Ruby の `ENV["X"]`）。結果は `String | nil` なので、`--strict`（レベル 2）は確かめずに使うことを `nil` の問題として報告します。必ずある変数には `fetch` を使います。

```ruby
ENV.set("SAKE_DOC_A", "1")
p(ENV.get("SAKE_DOC_A"))            # => "1"
p(ENV.get("SAKE_DOC_NOPE"))         # => nil
v = ENV.get("SAKE_DOC_A")
if v
  p(String.to_i(v) + 1)             # => 2
end
ENV.delete("SAKE_DOC_A")
```

```ruby error
home = ENV.get("HOME")
p(String.size(home))                # !> argument 1 may be nil
```

## fetch

`ENV.fetch(String, [String])`

変数の値（String）。設定されていなければ、第 2 引数があればそれを返し、無ければ `KeyError` です（Ruby の `ENV.fetch`。ブロック形はありません）。結果は nil になりません。

```ruby
ENV.set("SAKE_DOC_B", "x")
p(ENV.fetch("SAKE_DOC_B"))          # => "x"
p(ENV.fetch("SAKE_DOC_NOPE", "dflt"))   # => "dflt"
ENV.delete("SAKE_DOC_B")
```

```ruby error
ENV.fetch("SAKE_DOC_NOPE")          # !> KeyError: ENV.fetch: key not found: "SAKE_DOC_NOPE"
```

## set

`ENV.set(String, String)`

変数を設定し（あれば置き換え）、値を返します（Ruby の `ENV["X"] = v`）。値は String だけで、他の型は静的に `type` の問題です（消すのは `delete`）。空の名前や `=` を含む名前は OS が拒み、Ruby の `Errno::EINVAL` でプログラムが止まります（`IOError` にはなりません）。

```ruby
p(ENV.set("SAKE_DOC_C", "1"))       # => "1"
p(ENV.set("SAKE_DOC_C", "2"))       # => "2"
out, status = Open3.capture2("sh", "-c", "echo $SAKE_DOC_C")
p(out)                              # => "2\n"
ENV.delete("SAKE_DOC_C")
```

```ruby error
ENV.set("SAKE_DOC_C", 1)            # !> ENV.set: argument 2 must be String, but is Integer
```

## key?

`ENV.key?(String)`

変数が設定されていれば true（値が空文字列でも true）。

```ruby
ENV.set("SAKE_DOC_D", "")
p(ENV.key?("SAKE_DOC_D"))           # => true
p(ENV.key?("SAKE_DOC_NOPE"))        # => false
ENV.delete("SAKE_DOC_D")
```

## delete

`ENV.delete(String)`

変数を消し、消した値（String）を返します。設定されていなければ nil（`String | nil`、レベル 2）。

```ruby
ENV.set("SAKE_DOC_E", "1")
p(ENV.delete("SAKE_DOC_E"))         # => "1"
p(ENV.delete("SAKE_DOC_E"))         # => nil
p(ENV.key?("SAKE_DOC_E"))           # => false
```

## keys

`ENV.keys()`

設定されている変数の名前すべての Array（String）。順序は決まっていません。

```ruby
ENV.set("SAKE_DOC_F", "1")
p(Array.include?(ENV.keys, "SAKE_DOC_F"))   # => true
p(Array.include?(ENV.keys, "SAKE_DOC_NOPE"))   # => false
ENV.delete("SAKE_DOC_F")
```

## to_h

`ENV.to_h()`

環境全体の写しを Hash（String → String）で返します。写しなので、Hash を変えても環境は変わらず、以後の `ENV.set` も Hash に映りません。

```ruby
ENV.set("SAKE_DOC_G", "1")
h = ENV.to_h
p(h["SAKE_DOC_G"])                  # => "1"
h["SAKE_DOC_H"] = "2"
p(ENV.key?("SAKE_DOC_H"))           # => false
ENV.delete("SAKE_DOC_G")
p(Hash.key?(h, "SAKE_DOC_G"))       # => true
```
