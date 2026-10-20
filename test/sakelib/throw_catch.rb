# Kernel#throw and #catch, as ActiveSupport::Callbacks halts a chain with `throw :abort`.
def run_chain(steps)
  catch(:abort) do
    steps.each do |s|
      puts "  step #{s}"
      throw :abort if s == "halt"
    end
    true
  end
end
p run_chain(["a", "b"])
p run_chain(["a", "halt", "c"])

def search(rows, want)
  catch(:found) do
    rows.each_with_index do |row, i|
      row.each_with_index { |x, j| throw :found, [i, j] if x == want }
    end
    nil
  end
end
p search([[1, 2], [3, 4]], 4)
p search([[1, 2]], 9)

# Inner catches of other tags let a throw pass; ensure clauses run on the way out.
out = catch(:outer) do
  catch(:inner) do
    begin
      throw :outer, "left both"
    ensure
      puts "ensure ran"
    end
  end
  "not here"
end
p out
p catch(:t) { |tag| tag }

begin
  throw :nobody, 1
rescue UncaughtThrowError => e
  puts e.message
end
begin
  catch(:x) { throw :y }
rescue ArgumentError => e
  puts "#{e.class.name}: #{e.message}"
end
