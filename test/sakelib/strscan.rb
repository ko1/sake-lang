require "strscan"

# basic scanning (the example from Ruby's docs)
ss = StringScanner.new("This is an example string")
p(ss.eos?)
p(ss.scan(/\w+/))
p(ss.scan(/\w+/))
p(ss.scan(/\s+/))
p(ss.scan(/\s+/))
p(ss.scan(/\w+/))
p(ss.pos)
p(ss)
p(ss.scan_until(/ex/))
p(ss.matched)
p(ss.pre_match)
p(ss.post_match)
p(ss.skip(/ample/))
p(ss.skip_until(/str/))
p(ss.match?(/ing/))
p(ss.check(/in/))
p(ss.pos)
p(ss.rest)
p(ss.rest_size)
p(ss.getch)
p(ss.peek(10))
p(ss.check_until(/g/))
p(ss.exist?(/g/))
p(ss.exist?(/z/))
p(ss.terminate)
p(ss.eos?)
p(ss.getch)
p(ss.scan(/./))
p(ss.rest)

# groups, captures, named groups
ss = StringScanner.new("Fri Dec 12 1975 14:39")
p(ss.scan(/(\w+) (\w+) (\d+) /))
p(ss[0])
p(ss[1])
p(ss[3])
p(ss[4])
p(ss.captures)
p(ss.size)
p(ss.matched_size)
p(ss.scan(/(?<year>\d+) (?<h>\d+):(?<m>\d+)/))
p(ss["year"])
p(ss[:m])
p(ss.named_captures)
p(ss.scan(/x/))
p(ss[0])
p(ss.matched)
p(ss.matched?)
p(ss.captures)

# String patterns
ss = StringScanner.new("key=value; next")
p(ss.scan("key"))
p(ss.scan("value"))
p(ss.skip("="))
p(ss.scan_until(";"))
p(ss[0])
p(ss.pre_match)

# unscan, reset, pos=, charpos, bol?
ss = StringScanner.new("ab\ncd")
p(ss.scan(/ab/))
p(ss.unscan)
p(ss.pos)
p(ss.skip(/ab\n/))
p(ss.beginning_of_line?)
p(ss.pos = 1)
p(ss.bol?)
p(ss.scan(/b/))
p(ss.pos = -2)
p(ss.rest)
p(ss.reset)
p(ss.pos)
begin
  ss.scan(/zz/)
  ss.unscan
rescue ScanError => e
  puts("ScanError: #{e.message}")
end
begin
  ss.pos = 99
rescue RangeError => e
  puts("RangeError: #{e.message}")
end
begin
  ss.peek(-1)
rescue ArgumentError => e
  puts("ArgumentError: #{e.message}")
end

# string=, concat, scan_integer, peek_byte, empty input
ss = StringScanner.new("")
p(ss.eos?)
p(ss.scan(/\w*/))
p(ss.matched?)
p(ss.getch)
p(ss.peek(3))
p(ss.peek_byte)
p(ss)
ss.string = "12 -34 +5x"
p(ss.string)
p(ss.scan_integer)
ss.skip(/ /)
p(ss.scan_integer)
ss.skip(/ /)
p(ss.scan_integer)
p(ss.scan_integer)
p(ss.peek_byte)
ss.concat("yz")
p(ss.rest)

# anchors: \A and ^ match at the pointer
ss = StringScanner.new("aaXbb")
ss.skip(/aa/)
p(ss.scan(/\AX/))
p(ss.scan(/^b/))
p(ss.scan(/b$/))

# unicode: pos and sizes count bytes, charpos counts characters
ss = StringScanner.new("日本語 text")
p(ss.scan(/\p{Han}+/))
p(ss.pos)
p(ss.charpos)
p(ss.matched_size)
p(ss.getch)
p(ss.rest_size)
ss.reset
p(ss.getch)
p(ss.peek(6))
p(ss.pos = 6)
p(ss.scan(/./))

# a small tokenizer
def tokenize(src)
  ss = StringScanner.new(src)
  out = []
  until ss.eos?
    if ss.skip(/\s+/)
      next
    elsif (t = ss.scan(/\d+(\.\d+)?/))
      out.push([:num, t])
    elsif (t = ss.scan(/[a-z_]\w*/))
      out.push([:ident, t])
    elsif (t = ss.scan(/[-+*\/()=]/))
      out.push([:op, t])
    else
      raise ArgumentError, "unexpected #{ss.peek(1).inspect} at #{ss.pos}"
    end
  end
  out
end
p(tokenize("x = 3.14 * (y + 42)"))
begin
  tokenize("a $ b")
rescue ArgumentError => e
  puts(e.message)
end

# scan_full / search_full: the flags pick advancing and the result's type
ss = StringScanner.new("abc def")
p(ss.scan_full(/ab/, false, true))
p(ss.scan_full(/ab/, true, false))
p(ss.search_full(/e/, false, true))
p(ss.search_full(/e/, true, false))
p(ss.pointer)
p(ss.fixed_anchor?)

# << appends; a group name that does not exist
ss = StringScanner.new("ab")
ss << "cd" << "e"
p(ss.rest)
ss.scan("a")
begin
  p(ss[:x])
rescue IndexError => e
  puts("IndexError: #{e.message}")
end
ss.scan(/(?<y>b)/)
begin
  p(ss["x"])
rescue IndexError => e
  p(e.message.end_with?("undefined group name reference: x"))
end
p([StringScanner.new("a").rest?, StringScanner.new("").rest?])
