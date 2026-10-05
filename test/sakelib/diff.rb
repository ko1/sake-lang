require_relative "ref/diff"

def show_hunks(label, hunks)
  puts("#{label}:")
  hunks.each { |h| puts("  #{h.inspect}") }
end

seq1 = ["a", "b", "c", "e", "h", "j", "l", "m", "n", "p"]
seq2 = ["b", "c", "d", "e", "f", "j", "k", "l", "m", "r", "s", "t"]

puts("== lcs")
p(Diff::LCS.lcs(seq1, seq2))
p(Diff::LCS.lcs("abcxyz", "xbczya"))
p(Diff::LCS.lcs([1, 2, 3], [4, 5]))
p(Diff::LCS.lcs([], [1]))

puts("== diff")
d = Diff::LCS.diff(seq1, seq2)
show_hunks("seq", d)
show_hunks("strings", Diff::LCS.diff("abcd", "acbd"))
show_hunks("same", Diff::LCS.diff("same", "same"))
show_hunks("to empty", Diff::LCS.diff([1, 2], []))
(d.first || []).each do |c|
  p([c.action, c.position, c.element, c.adding?, c.deleting?])
end

puts("== sdiff")
s = Diff::LCS.sdiff(seq1, seq2)
s.each { |c| p(c) }
p(Diff::LCS.sdiff("abc", "axc").map(&:to_a))
p(s.count(&:changed?))
p(Diff::LCS.sdiff([], ["x"]).map(&:to_a))

puts("== traverse")
Diff::LCS.traverse_sequences("abc", "bcd") { |kind, i, j| puts("#{kind} #{i} #{j}") }
Diff::LCS.traverse_balanced("abc", "xbz") { |kind, i, j| puts("#{kind} #{i} #{j}") }

puts("== patch")
p(Diff::LCS.patch(seq1, d) == seq2)
p(Diff::LCS.unpatch(seq2, d) == seq1)
p(Diff::LCS.patch(seq1, s) == seq2)
p(Diff::LCS.unpatch(seq2, s) == seq1)
p(Diff::LCS.patch("kitten", Diff::LCS.diff("kitten", "sitting")))
p(Diff::LCS.patch("kitten", Diff::LCS.sdiff("kitten", "sitting")))
p(Diff::LCS.unpatch("sitting", Diff::LCS.diff("kitten", "sitting")))
p(Diff::LCS.patch("abc", []))

puts("== lines")
old = "one\ntwo\nthree\nfour\nfive\n".lines
nw = "zero\none\nthree\nfour\n4.5\nfive\n".lines
Diff::LCS.sdiff(old, nw).each do |c|
  case c.action
  when "=" then print("  ", c.old_element)
  when "-" then print("- ", c.old_element)
  when "+" then print("+ ", c.new_element)
  when "!"
    print("- ", c.old_element)
    print("+ ", c.new_element)
  end
end
words = Diff::LCS.lcs("the quick brown fox jumps".split(" "), "the slow brown dog jumps high".split(" "))
p(words)

puts("== errors")
begin
  Diff::LCS::Change.new(:bad, 0, "x")
  raise NoMatchingPatternError unless :bad.is_a?(String)
rescue NoMatchingPatternError => e
  puts("NoMatchingPatternError")
end
