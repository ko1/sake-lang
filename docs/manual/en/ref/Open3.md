# Open3

Open3 is the group of operations that run a child process and collect its output and exit status (`capture2`, `capture2e`, and `capture3` of Ruby's `open3` library; they are built in because a Sake program has no other way to start a child process. For just true/false without the output use `Kernel.system`, see [Built-ins](../09-builtins.md)).

Ruby's result is an Array `[out, status]` with a `Process::Status`; in Sake it is a **Tuple** and the exit status an **Integer** (the exit code, or -1 when the child was killed by a signal). Take it apart with multiple assignment, `out, status = Open3.capture2(...)`. A command that is not found or cannot start is an `IOError`. As in Ruby, a single argument is interpreted by the shell; with two or more, the first is the program and the rest its arguments (no shell). No standard input can be given (there is no `stdin_data:`).

Open3 has no operators.

## capture2

`Open3.capture2(String, *String)`

Runs the command and returns the Tuple `[stdout, status]` (String, Integer). The child's stderr goes to this process's stderr.

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

Runs the command and returns `[output, status]` (String, Integer) with stdout and stderr merged into one String (Ruby's `capture2e`).

```ruby
out, status = Open3.capture2e("sh", "-c", "echo err >&2; echo out; exit 2")
p(out)                              # => "err\nout\n"
p(status)                           # => 2
```

## capture3

`Open3.capture3(String, *String)`

Runs the command and returns the Tuple `[stdout, stderr, status]` (String, String, Integer).

```ruby
out, err, status = Open3.capture3("sh", "-c", "echo err >&2; echo out; exit 2")
p(out)                              # => "out\n"
p(err)                              # => "err\n"
p(status)                           # => 2
p(Open3.capture3("true"))           # => ["", "", 0]
killed = Open3.capture3("sh", "-c", "kill -9 $$")
p(killed[2])                        # => -1
```
