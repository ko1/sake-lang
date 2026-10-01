class NotSupported < StandardError
  attr_reader :n

  def initialize(message, n)
    super(message)
    @n = n
  end
end

module Build
  module_function

  def blank(n) = Array.new(n) { Array.new(n, 0) }

  # Siamese method: start top middle, move up-right, drop down when blocked
  def odd(n)
    sq = blank(n)
    r = 0
    c = n / 2
    (1..(n * n)).each do |k|
      sq[r][c] = k
      nr = (r - 1) % n
      nc = (c + 1) % n
      if sq[nr][nc] != 0
        nr = (r + 1) % n
        nc = c
      end
      r = nr
      c = nc
    end
    sq
  end

  # doubly even: keep k where the 4x4 pattern says so, otherwise n*n+1-k
  def doubly_even(n)
    sq = blank(n)
    n.times do |r|
      n.times do |c|
        k = r * n + c + 1
        diagonal = (r % 4 == c % 4) || ((r % 4) + (c % 4) == 3)
        sq[r][c] = diagonal ? n * n + 1 - k : k
      end
    end
    sq
  end

  def square(n)
    if n.odd?
      odd(n)
    elsif n % 4 == 0
      doubly_even(n)
    else
      raise NotSupported.new("singly even sizes are not built here", n)
    end
  end
end

module Check
  module_function

  def lines(sq)
    n = sq.size
    out = sq.each_with_index.map { |row, r| ["row #{r + 1}", row.sum] }
    n.times { |c| out << ["col #{c + 1}", sq.sum { |row| row[c] }] }
    out << ["diag", (0...n).sum { |i| sq[i][i] }]
    out << ["anti", (0...n).sum { |i| sq[i][n - 1 - i] }]
    out
  end

  def magic_constant(n) = n * (n * n + 1) / 2

  def normal?(sq)
    n = sq.size
    values = sq.flatten
    values.uniq.size == n * n && values.all? { |v| v.between?(1, n * n) }
  end

  def report(sq)
    target = magic_constant(sq.size)
    wrong = lines(sq).reject { |_name, sum| sum == target }
    { magic: wrong.empty?, normal: normal?(sq), target: target, wrong: wrong }
  end
end

def show(sq)
  width = (sq.size * sq.size).to_s.size
  sq.each { |row| puts row.map { it.to_s.rjust(width) }.join(" ") }
end

[3, 4, 5, 6, 8].each do |n|
  sq = Build.square(n)
  Check.report(sq) => { magic:, normal:, target: }
  puts "n=#{n}: magic=#{magic} normal=#{normal} constant=#{target}"
  show(sq) if n <= 5
rescue NotSupported => e
  puts "n=#{e.n}: #{e.message}"
end

candidates = {
  "lo shu" => [[4, 9, 2], [3, 5, 7], [8, 1, 6]],
  "swapped" => [[4, 9, 2], [3, 5, 7], [8, 6, 1]],
  "all fives" => [[5, 5, 5], [5, 5, 5], [5, 5, 5]],
  "durer" => [[16, 3, 2, 13], [5, 10, 11, 8], [9, 6, 7, 12], [4, 15, 14, 1]],
}
candidates.each do |name, sq|
  Check.report(sq) => { magic:, normal:, wrong: }
  detail = wrong.map { |line, sum| "#{line}=#{sum}" }.join(", ")
  puts "#{name}: #{magic ? "magic" : "not magic"}#{normal ? "" : " (not normal)"}#{wrong.empty? ? "" : " [#{detail}]"}"
end
