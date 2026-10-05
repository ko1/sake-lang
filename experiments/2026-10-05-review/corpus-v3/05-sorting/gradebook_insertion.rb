class Student
  attr_reader :name, :score, :submitted

  def initialize(name, score, submitted)
    @name = name
    @score = score
    @submitted = submitted
  end

  def to_s = format("%-8s %3d  (day %d)", @name, @score, @submitted)
end

# Stable insertion sort: higher score first; equal scores keep submission order.
def insertion_sort(students)
  a = students.dup
  shifts = 0
  (1...a.size).each do |i|
    cur = a[i]
    j = i - 1
    while j >= 0 && a[j].score < cur.score
      a[j + 1] = a[j]
      j -= 1
      shifts += 1
    end
    a[j + 1] = cur
  end
  [a, shifts]
end

# Position where a new student goes in an already sorted roster (after equal scores).
def insert_position(sorted, score)
  lo = 0
  hi = sorted.size
  while lo < hi
    mid = (lo + hi) / 2
    if sorted[mid].score >= score
      lo = mid + 1
    else
      hi = mid
    end
  end
  lo
end

def ranks(sorted)
  prev = nil
  rank = 0
  sorted.each_with_index.map do |s, i|
    rank = i + 1 if prev.nil? || s.score != prev
    prev = s.score
    [rank, s]
  end
end

def letter(score)
  if score >= 90 then "A"
  elsif score >= 80 then "B"
  elsif score >= 70 then "C"
  elsif score >= 60 then "D"
  else "F"
  end
end

roster = [
  Student.new("alice", 88, 1), Student.new("bob", 72, 1), Student.new("carol", 95, 2),
  Student.new("dave", 88, 2), Student.new("erin", 59, 3), Student.new("frank", 72, 3),
  Student.new("grace", 100, 4), Student.new("heidi", 81, 4), Student.new("ivan", 88, 5)
]

sorted, shifts = insertion_sort(roster)
puts "Sorted roster (#{shifts} shifts):"
ranks(sorted).each { |r, s| puts "  #{r.to_s.rjust(2)}. #{s}" }

late = [Student.new("judy", 88, 6), Student.new("ken", 40, 6), Student.new("leo", 97, 7)]
late.each do |s|
  pos = insert_position(sorted, s.score)
  sorted.insert(pos, s)
  puts "late #{s.name} inserted at #{pos}"
end

puts "Final ranking:"
ranks(sorted).each do |r, s|
  puts format("  %2d. %s  %s", r, s, letter(s.score))
end

dist = Hash.new(0)
sorted.each { |s| dist[letter(s.score)] += 1 }
puts "Distribution: " + %w[A B C D F].map { |g| "#{g}=#{dist[g]}" }.join(" ")
top = sorted.find { |s| s.submitted >= 5 }
puts "Best late-week: #{top ? top.name : "none"}"
