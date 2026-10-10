# File

File is the group of operations that work on a file by its path (a String). There is no value of type File: `File.open` returns an `IO` ([IO](IO.md)), and the other operations take a path and read, write, or query the file on the spot. They have the names of Ruby's class methods, `File.read(path)` and so on; what Ruby does with instance methods (`file.read`) is an `IO` operation ([Values and types](../03-values.md), [Built-ins](../09-builtins.md)).

A failing system call (a missing path, permissions, reading a directory; Ruby's `Errno::ENOENT` and the like) is an `IOError` with Ruby's message ([Exceptions](../08-exceptions.md)). The path operations (`basename`, `join`, `expand_path`, ...) do not look at the file system. The predicates (`exist?`, ...) never fail; they return false.

File has no operators. The examples run in an empty directory and create files there.

## open

`File.open(String, [String], [Integer]) [{ }]`

Opens the file and returns an `IO`. The second argument is the mode, `"r"` when omitted (as Ruby's: `"r"` read, `"w"` write (truncating), `"a"` append, `"r+"` read and write, `"w+"`, `"a+"`, and `"b"` for binary). The third argument is the permission bits for a newly created file (`0o600`; an existing file is not changed). With a block, the `IO` is passed to the block, the file is closed after it, and **the block's value** is returned (as in Ruby). Without a block, close it with `IO.close`. A missing or unreadable file is an `IOError`; an unknown mode is an `ArgumentError`.

```ruby
f = File.open("a.txt", "w")
IO.puts(f, "one")
IO.close(f)
n = File.open("a.txt", "a") { |io| IO.write(io, "two\n") }
p(n)                                # => 4
p(File.open("a.txt") { |io| IO.readlines(io) })   # => ["one\n", "two\n"]
File.open("p.txt", "w", 0o600) { |io| nil }
p(File.exist?("p.txt"))             # => true
```

```ruby error
File.open("nope.txt")               # !> IOError: File.open: No such file or directory
```

## read

`File.read(String)`

The whole file as a String. A missing file or a directory is an `IOError`.

```ruby
File.write("a.txt", "hello\n")
p(File.read("a.txt"))               # => "hello\n"
```

```ruby error
File.read("nope.txt")               # !> IOError: File.read: No such file or directory
```

## readlines

`File.readlines(String)`

The whole file as an Array of Strings, one per line (each keeps its newline). An empty file gives an empty Array.

```ruby
File.write("a.txt", "a\nb\n")
p(File.readlines("a.txt"))          # => ["a\n", "b\n"]
```

## write

`File.write(String, String)`

Creates the file (or replaces its content) with the string and returns the number of bytes written (an Integer). It does not append (append with `File.open(path, "a")`). The second argument must be a String; another type is a `type` problem statically.

```ruby
p(File.write("a.txt", "日本"))      # => 6
p(File.write("a.txt", "x"))         # => 1
p(File.read("a.txt"))               # => "x"
```

```ruby error
File.write("a.txt", 1)              # !> File.write: argument 2 must be String, but is Integer
```

## exist?

`File.exist?(String)`

True when a file or directory is at the path. It never fails.

```ruby
File.write("a.txt", "")
p(File.exist?("a.txt"))             # => true
p(File.exist?("."))                 # => true
p(File.exist?("nope"))              # => false
```

## file?, directory?, symlink?

`File.file?(String)`

`File.directory?(String)`

`File.symlink?(String)`

True for a regular file, a directory, or a symbolic link. `file?` and `directory?` follow links and look at the target. A missing path is false.

```ruby
File.write("a.txt", "")
File.symlink("a.txt", "l1.txt")
p(File.file?("a.txt"))              # => true
p(File.file?("."))                  # => false
p(File.directory?("."))             # => true
p(File.symlink?("l1.txt"))           # => true
p(File.symlink?("a.txt"))           # => false
p(File.file?("nope"))               # => false
```

## zero?, empty?

`File.zero?(String)`

`File.empty?(String)`

True when the file exists and has size 0 (the two are the same, as in Ruby). A missing path is false.

```ruby
File.write("e.txt", "")
File.write("a.txt", "x")
p(File.zero?("e.txt"))              # => true
p(File.empty?("a.txt"))             # => false
p(File.zero?("nope"))               # => false
```

## readable?, writable?, executable?

`File.readable?(String)`

`File.writable?(String)`

`File.executable?(String)`

True when this process can read, write, or execute the path. A missing path is false.

```ruby
File.write("a.txt", "")
p(File.readable?("a.txt"))          # => true
p(File.writable?("a.txt"))          # => true
p(File.executable?("a.txt"))        # => false
File.chmod(0o755, "a.txt")
p(File.executable?("a.txt"))        # => true
```

## size

`File.size(String)`

The size of the file in bytes (an Integer). A missing path is an `IOError`.

```ruby
File.write("a.txt", "日本")
p(File.size("a.txt"))               # => 6
```

```ruby error
File.size("nope")                   # !> IOError: File.size: No such file or directory
```

## mtime, atime

`File.mtime(String)`

`File.atime(String)`

The time of the last modification or the last access, as a Time. A missing path is an `IOError`.

```ruby
File.write("a.txt", "")
File.utime(Time.at(0), Time.at(60), "a.txt")
p(Time.to_i(File.atime("a.txt")))   # => 0
p(Time.to_i(File.mtime("a.txt")))   # => 60
p(File.mtime("a.txt") <= Time.now)  # => true
```

## ftype

`File.ftype(String)`

The kind as a String: `"file"`, `"directory"`, `"link"` (the link itself; not followed), `"characterSpecial"`, and the others as in Ruby. A missing path is an `IOError`.

```ruby
File.write("a.txt", "")
File.symlink("a.txt", "l2.txt")
p(File.ftype("a.txt"))              # => "file"
p(File.ftype("."))                  # => "directory"
p(File.ftype("l2.txt"))              # => "link"
```

## identical?

`File.identical?(String, String)`

True when the two paths name the same file (links are followed; a hard link counts as the same). False when either is missing.

```ruby
File.write("a.txt", "")
File.write("b.txt", "")
File.symlink("a.txt", "l3.txt")
p(File.identical?("a.txt", "l3.txt"))   # => true
p(File.identical?("a.txt", "b.txt"))   # => false
p(File.identical?("a.txt", "nope"))    # => false
```

## rename

`File.rename(String, String)`

Moves (renames) the file and returns 0. An existing file at the new path is replaced. A missing source is an `IOError`.

```ruby
File.write("a.txt", "x")
p(File.rename("a.txt", "b.txt"))    # => 0
p(File.exist?("a.txt"))             # => false
p(File.read("b.txt"))               # => "x"
```

```ruby error
File.rename("nope", "b.txt")        # !> IOError: File.rename: No such file or directory
```

## delete, unlink

`File.delete(String)`

`File.unlink(String, *String)`

Remove files. `delete` takes one path and returns 1; `unlink` takes one or more and returns how many it removed (an Integer). A directory cannot be removed this way (`Dir.rmdir`). A missing path is an `IOError` (Ruby's `Errno::ENOENT`).

```ruby
File.write("a.txt", "")
File.write("b.txt", "")
File.write("c.txt", "")
p(File.delete("a.txt"))             # => 1
p(File.unlink("b.txt", "c.txt"))    # => 2
p(File.exist?("c.txt"))             # => false
```

```ruby error
File.delete("nope")                 # !> IOError: File.delete: No such file or directory
```

## symlink, link

`File.symlink(String, String)`

`File.link(String, String)`

`symlink(target, link)` makes a symbolic link, `link(target, link)` a hard link; both return 0. An existing `link` path is an `IOError`.

```ruby
File.write("a.txt", "x")
p(File.symlink("a.txt", "s.txt"))   # => 0
p(File.link("a.txt", "h.txt"))      # => 0
p(File.read("s.txt"))               # => "x"
p(File.symlink?("h.txt"))           # => false
p(File.identical?("a.txt", "h.txt"))   # => true
```

```ruby error
File.write("a.txt", "")
File.symlink("a.txt", "a.txt")      # !> IOError: File.symlink: File exists
```

## readlink

`File.readlink(String)`

The path a symbolic link points to, as a String (as written; not resolved). A path that is not a link is an `IOError`.

```ruby
File.write("a.txt", "")
File.symlink("a.txt", "l4.txt")
p(File.readlink("l4.txt"))           # => "a.txt"
```

```ruby error
File.write("a.txt", "")
File.readlink("a.txt")              # !> IOError: File.readlink: Invalid argument
```

## chmod

`File.chmod(Integer, *String)`

Sets the permission bits to `mode` (`0o644`, ...) and returns the number of files changed; 0 with no paths. A missing path is an `IOError`.

```ruby
File.write("a.txt", "")
File.write("b.sh", "")
p(File.chmod(0o755, "a.txt", "b.sh"))   # => 2
p(File.executable?("b.sh"))         # => true
p(File.chmod(0o644))                # => 0
```

## utime

`File.utime(Time|Nil, Time|Nil, *String)`

`utime(atime, mtime, *paths)`: sets the access and modification times and returns the number of files changed. nil means now. A missing path is an `IOError`.

```ruby
File.write("a.txt", "")
p(File.utime(Time.at(10), Time.at(20), "a.txt"))   # => 1
p(Time.to_i(File.atime("a.txt")))   # => 10
p(Time.to_i(File.mtime("a.txt")))   # => 20
File.utime(nil, nil, "a.txt")
p(File.mtime("a.txt") > Time.at(20))   # => true
```

## basename

`File.basename(String, [String])`

The last component of the path. A second argument names an extension (`".rb"`) to strip; `".*"` strips any extension. The file system is not consulted.

```ruby
p(File.basename("/a/b/c.rb"))       # => "c.rb"
p(File.basename("/a/b/c.rb", ".rb"))   # => "c"
p(File.basename("c.tar.gz", ".*"))  # => "c.tar"
p(File.basename("/a/b/"))           # => "b"
```

## dirname

`File.dirname(String, [Integer])`

The directory part, without the last component. A second argument `n` goes up `n` levels (1 when omitted; 0 gives the path unchanged). Without a directory part it is `"."`.

```ruby
p(File.dirname("/a/b/c.rb"))        # => "/a/b"
p(File.dirname("/a/b/c.rb", 2))     # => "/a"
p(File.dirname("c.rb"))             # => "."
```

## extname

`File.extname(String)`

The extension of the last component, with its dot; `""` when there is none. A name that starts with a dot (`.bashrc`) has no extension.

```ruby
p(File.extname("c.tar.gz"))         # => ".gz"
p(File.extname("c"))                # => ""
p(File.extname(".bashrc"))          # => ""
```

## split

`File.split(String)`

The two-element Tuple `[dirname, basename]` (String, String). In Ruby it is an Array; in Sake it is a Tuple, taken apart with `dir, base = File.split(p)`.

```ruby
dir, base = File.split("/a/b/c.rb")
p(dir)                              # => "/a/b"
p(base)                             # => "c.rb"
p(File.split("c.rb"))               # => [".", "c.rb"]
```

## join

`File.join(*String|Array)`

The parts joined with `/`; doubled `/` are collapsed. The arguments are Strings or Arrays of Strings (nested Arrays are flattened); with no arguments it is `""`. Another type is a `type` problem statically.

```ruby
p(File.join("a", "b", "c.rb"))      # => "a/b/c.rb"
p(File.join("a/", "/b"))            # => "a/b"
p(File.join(Array["a", "b"], "c"))  # => "a/b/c"
p(File.join())                      # => ""
```

```ruby error
File.join(1)                        # !> File.join: argument 1 must be String|Array, but is Integer
```

## expand_path, absolute_path

`File.expand_path(String, [String])`

`File.absolute_path(String, [String])`

Make a relative path absolute. The second argument is the base directory, the current directory (`Dir.pwd`) when omitted. `.` and `..` are resolved, but the file system is not consulted and links are not followed. They differ on `~`: `expand_path` expands `~` to the home directory (`~user` for an unknown user is an `ArgumentError`), `absolute_path` leaves it as it is (as in Ruby).

```ruby
p(File.expand_path("/x/../y"))      # => "/y"
p(File.expand_path("b", "/a"))      # => "/a/b"
p(File.absolute_path("b", "/a"))    # => "/a/b"
p(File.expand_path("a") == File.join(Dir.pwd, "a"))   # => true
p(File.expand_path("~") == Dir.home)                  # => true
p(File.absolute_path("~") == File.join(Dir.pwd, "~")) # => true
```

## absolute_path?

`File.absolute_path?(String)`

True when the path is absolute (starts with `/`). The file system is not consulted.

```ruby
p(File.absolute_path?("/a/b"))      # => true
p(File.absolute_path?("a/b"))       # => false
```

## realpath

`File.realpath(String, [String])`

The real absolute path with every symbolic link followed. The second argument is the base directory for a relative path. The path must exist; a missing one is an `IOError` (the difference from `expand_path`).

```ruby
File.write("a.txt", "")
File.symlink("a.txt", "l5.txt")
p(File.realpath("l5.txt") == File.join(Dir.pwd, "a.txt"))   # => true
p(File.realpath("l5.txt", Dir.pwd) == File.realpath("./a.txt"))   # => true
```

```ruby error
File.realpath("nope")               # !> IOError: File.realpath: No such file or directory
```
