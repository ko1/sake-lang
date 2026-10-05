# frozen_string_literal: true

# Rewrites field reads `T.get_x(v)` / `v.T.get_x` / `(A|B).get_x(v)` / `get_x(v)` into `T.x(v)` / `v.T.x` / ... (2026-10-05: a field's reader has
# the field's name). A name the file defines itself as `def get_x` is left alone (an ordinary function).
# usage: ruby tools/convert_get_readers.rb FILE...   (rewrites in place; prints the changed files)
ARGV.each do |path|
  src = File.read(path)
  own = src.scan(/def (?:[A-Z]\w*\.)?get_(\w+)/).flatten
  out = src.gsub(/(?<![\w@])([A-Z]\w*)\.get_(\w+)/) { own.include?($2) ? $& : "#{$1}.#{$2}" }
  out = out.gsub(/\)\.get_(\w+)/) { own.include?($1) ? $& : ").#{$1}" }               # (A|B).get_x(v)
  out = out.gsub(/(?<![.\w@:])get_(\w+)\(/) { own.include?($1) ? $& : "#{$1}(" }       # get_x(v) inside the class
  next if out == src
  File.write(path, out)
  puts path
end
