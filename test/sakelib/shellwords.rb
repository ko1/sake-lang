require "shellwords"

lines = [
  "",
  "   ",
  "ls -la /tmp",
  "  leading and   trailing  ",
  "a 'b c' \"d e\" f\\ g",
  "echo \"say \\\"hi\\\"\" 'it'\\''s'",
  "\"\\$HOME \\` \\\\ \\a\"",
  "foo\\\nbar",
  "a\"b\"c'd'e",
  "''",
  "\"\" x ''",
  "x\\",
  "日本 'ご飯' \"です\"",
  "tab\tsep\nline"
]
lines.each { |l| p Shellwords.split(l) }
p Shellwords.shellsplit("one two")
p Shellwords.shellwords("one 'two three'")
p "x y z".shellsplit

# unbalanced quotes and NUL
["a 'b", "\"open", "ok \"x y", "a\u0000b", "abc def 'g"].each do |l|
  begin
    p Shellwords.split(l)
  rescue ArgumentError => e
    puts "ArgumentError: #{e.message}"
  end
end

# escape
["", "simple", "with space", "it's", "a\"b", "$HOME", "a\nb", "日本", "a-b_c.d,e:f+g/h@i", "*?[]{}()<>|&;!#~=%^"].each do |s|
  p Shellwords.escape(s)
end
p Shellwords.shellescape(42)
p "x y".shellescape
begin
  Shellwords.escape("a\u0000b")
rescue ArgumentError => e
  puts "ArgumentError: #{e.message}"
end

# join, and join then split gives the words back
words = ["ls", "my file.txt", "", "it's", "a\nb", "$x"]
cmd = Shellwords.join(words)
p cmd
p Shellwords.split(cmd) == words
p Shellwords.shelljoin(["a", 1, :b])
p ["x y", "z"].shelljoin
