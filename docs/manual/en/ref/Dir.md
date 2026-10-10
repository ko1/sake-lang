# Dir

Dir is the group of operations that work on a directory by its path (a String). There is no value of type Dir (no `Dir.open`, no `Dir` object as in Ruby); every operation has the name and the result of Ruby's class method of the same name ([Built-ins](../09-builtins.md)). Listings come back as Arrays of Strings.

A failing system call (a missing directory, removing a directory that is not empty; Ruby's `Errno::ENOENT` and the like) is an `IOError` with Ruby's message ([Exceptions](../08-exceptions.md)). `exist?` never fails and returns false; `glob` returns an empty Array when nothing matches.

Dir has no operators. The examples run in an empty directory and create directories there.

## children, entries

`Dir.children(String)`

`Dir.entries(String)`

The names (names only, not paths) in the directory, as an Array. `children` leaves out `.` and `..`; `entries` includes them. The order is the OS's and not defined, so `Array.sort` before relying on it. A missing directory is an `IOError`.

```ruby
Dir.mkdir("d1")
File.write("d1/a.txt", "")
File.write("d1/b.rb", "")
p(Array.sort(Dir.children("d1")))   # => ["a.txt", "b.rb"]
p(Array.sort(Dir.entries("d1")))    # => [".", "..", "a.txt", "b.rb"]
```

```ruby error
Dir.children("nope")                # !> IOError: Dir.children: No such file or directory
```

## each_child

`Dir.each_child(String) { }`

Passes each name of `children` to the block in turn and returns nil (Ruby returns the Dir; Sake returns nil). The block's value is not used. The order is undefined, as for `children`. A missing directory is an `IOError`.

```ruby
Dir.mkdir("d2")
File.write("d2/x", "")
File.write("d2/y", "")
names = Array[]
r = Dir.each_child("d2") { |n| Array.push(names, n) }
p(Array.sort(names))                # => ["x", "y"]
p(r)                                # => nil
```

## glob

`Dir.glob(String|Array, [base: String])`

The paths that match the pattern, as an Array (Ruby's `Dir.glob`, with `*`, `?`, `[...]`, `{a,b}`, and `**/`). The pattern is a String or an Array of Strings (a path matching any of them). The result is sorted, as Ruby's, and a name that starts with a dot does not match `*`. With the keyword `base:` the search starts in that directory and the result holds **relative names**. When nothing matches, or the `base:` directory is missing, the result is an empty Array; it does not fail.

```ruby
Dir.mkdir("d3")
File.write("d3/a.txt", "")
File.write("d3/b.rb", "")
Dir.mkdir("d3/sub")
File.write("d3/sub/c.txt", "")
p(Dir.glob("d3/*.rb"))              # => ["d3/b.rb"]
p(Dir.glob("d3/**/*.txt"))          # => ["d3/a.txt", "d3/sub/c.txt"]
p(Dir.glob(Array["d3/*.txt", "d3/*.rb"]))   # => ["d3/a.txt", "d3/b.rb"]
p(Dir.glob("*", base: "d3"))        # => ["a.txt", "b.rb", "sub"]
p(Dir.glob("nope/*"))               # => []
```

## exist?

`Dir.exist?(String)`

True when a directory is at the path. A file or a missing path is false; it never fails.

```ruby
Dir.mkdir("d4")
File.write("f4", "")
p(Dir.exist?("d4"))                 # => true
p(Dir.exist?("f4"))                 # => false
p(Dir.exist?("nope"))               # => false
```

## empty?

`Dir.empty?(String)`

True when the directory holds nothing but `.` and `..`. A missing directory is an `IOError`.

```ruby
Dir.mkdir("d5")
p(Dir.empty?("d5"))                 # => true
File.write("d5/a", "")
p(Dir.empty?("d5"))                 # => false
```

## mkdir

`Dir.mkdir(String, [Integer])`

Creates one directory and returns 0. The second argument is the permission bits (`0o700`; when omitted, `0o777` reduced by the umask). A missing parent, or an existing entry of the same name, is an `IOError` (there is no counterpart of `mkdir -p`).

```ruby
p(Dir.mkdir("d6"))                  # => 0
p(Dir.mkdir("d6/sub", 0o700))       # => 0
p(Dir.exist?("d6/sub"))             # => true
```

```ruby error
Dir.mkdir("d6b")
Dir.mkdir("d6b")                    # !> IOError: Dir.mkdir: File exists
```

## rmdir, unlink

`Dir.rmdir(String)`

`Dir.unlink(String)`

Remove an empty directory and return 0 (the two are the same, as in Ruby). A directory that is not empty, or a missing path, is an `IOError`. Files are removed with `File.delete`.

```ruby
Dir.mkdir("d7")
p(Dir.rmdir("d7"))                  # => 0
p(Dir.exist?("d7"))                 # => false
Dir.mkdir("d7")
p(Dir.unlink("d7"))                 # => 0
```

```ruby error
Dir.mkdir("d7b")
File.write("d7b/a", "")
Dir.rmdir("d7b")                    # !> IOError: Dir.rmdir: Directory not empty
```

## pwd

`Dir.pwd()`

The absolute path of the current directory. Sake has no `Dir.chdir`, so it does not change while the program runs.

```ruby
p(File.absolute_path?(Dir.pwd))     # => true
p(Dir.pwd == File.expand_path("."))   # => true
```

## home

`Dir.home([String])`

The absolute path of the home directory; with a user name, that user's home. An unknown user is an `ArgumentError`.

```ruby
p(Dir.home == ENV.fetch("HOME"))    # => true
p(File.expand_path("~") == Dir.home)   # => true
```

```ruby error
Dir.home("no_such_user_xyz")        # !> ArgumentError: Dir.home: user no_such_user_xyz doesn't exist
```

## tmpdir

`Dir.tmpdir()`

The absolute path of the directory for temporary files (`$TMPDIR`, or `/tmp`).

```ruby
p(Dir.exist?(Dir.tmpdir))           # => true
p(File.absolute_path?(Dir.tmpdir))  # => true
```

## mktmpdir

`Dir.mktmpdir([String], [String]) [{ }]`

Creates a new temporary directory. The first argument is a prefix for its name (`"d"` when omitted), the second the directory to create it in (`Dir.tmpdir` when omitted). Without a block it returns the path (a String) and removing it is the caller's job (`Dir.rmdir` only while it is empty). With a block, the path is passed to the block, the directory is removed **with its contents** after the block, and the block's value is returned (as Ruby's `tmpdir`). A missing parent directory is an `IOError`.

```ruby
t = Dir.mktmpdir("pfx", ".")
p(String.start_with?(File.basename(t), "pfx"))   # => true
p(Dir.exist?(t))                    # => true
Dir.rmdir(t)
kept = ""
v = Dir.mktmpdir { |dir| File.write(File.join(dir, "f"), "1"); kept = dir; 42 }
p(v)                                # => 42
p(Dir.exist?(kept))                 # => false
```
