# Open3

Open3 は子プロセスを走らせて出力と終了状態を集める操作の集まりです（Ruby の `open3` ライブラリの `capture2`、`capture2e`、`capture3`。Sake のプログラムは他に子プロセスを起こす手段が無いので組み込みです。出力を集めず true/false だけ欲しければ `Kernel.system`。[組み込み](../09-builtins.md)）。

Ruby の結果は Array `[out, status]` で `status` は `Process::Status` ですが、Sake では **Tuple** で、終了状態は **Integer**（終了コード。シグナルで死んだときは -1）です。`out, status = Open3.capture2(...)` と多重代入で受けます。コマンドが見つからない・起動できないときは `IOError`。コマンドは Ruby と同じく、1 引数なら shell で解釈、2 引数以上なら第 1 引数がプログラムで残りが引数（shell を通しません）。標準入力は与えられません（Ruby の `stdin_data:` はありません）。

Open3 に演算子はありません。

## capture2

`Open3.capture2(String, *String)`

コマンドを走らせ、`[stdout, status]`（String, Integer）の Tuple を返します。子の stderr はこのプロセスの stderr にそのまま流れます。

```ruby
out, status = Open3.capture2("echo", "hi")
p(out)                              # => "hi\n"
p(status)                           # => 0
out2, status2 = Open3.capture2("sh", "-c", "echo $0; exit 3")
p(out2)                             # => "sh\n"
p(status2)                          # => 3
```

```ruby error
Open3.capture2("no_such_command_xyz")   # !> IOError: Open3.capture2: No such file or directory - no_such_command_xyz
```

## capture2e

`Open3.capture2e(String, *String)`

コマンドを走らせ、stdout と stderr を 1 つに混ぜた `[output, status]`（String, Integer）の Tuple を返します（Ruby の `capture2e`）。

```ruby
out, status = Open3.capture2e("sh", "-c", "echo err >&2; echo out; exit 2")
p(out)                              # => "err\nout\n"
p(status)                           # => 2
```

## capture3

`Open3.capture3(String, *String)`

コマンドを走らせ、`[stdout, stderr, status]`（String, String, Integer）の Tuple を返します。

```ruby
out, err, status = Open3.capture3("sh", "-c", "echo err >&2; echo out; exit 2")
p(out)                              # => "out\n"
p(err)                              # => "err\n"
p(status)                           # => 2
p(Open3.capture3("true"))           # => ["", "", 0]
killed = Open3.capture3("sh", "-c", "kill -9 $$")
p(killed[2])                        # => -1
```
