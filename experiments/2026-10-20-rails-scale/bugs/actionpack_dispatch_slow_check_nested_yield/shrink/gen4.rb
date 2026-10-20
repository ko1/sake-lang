# gen4.rb S D: `resources` yields to the caller's block; it also reaches itself again through a chain of D
# functions (hop1 -> ... -> resources), each passing `{ yield }` on; hop1 has S call sites of the next step.
s, d = ARGV.map(&:to_i)
hops = (1...d).map do |i|
  nxt = i + 1 < d ? "hop#{i + 1}" : "resources"
  calls = i == 1 ? (1..s).map { |j| "    return #{nxt}(m, kind) { yield } if kind == #{j}\n" }.join : "    #{nxt}(m, kind) { yield }\n"
  "  def hop#{i}(m, kind)\n#{calls}    nil\n  end\n"
end.join
first = d == 1 ? (1..s).map { |j| "    return resources(m, 0) { yield } if kind == #{j}\n" }.join : "    return hop1(m, kind - 100) { yield } if kind > 100\n"
puts <<~S
  class Mapper
    attr_accessor routes
  #{hops}
    def resources(m, kind)
  #{first}
      yield
      Array.push(@routes, kind)
      nil
    end
  end
  m = Mapper.new(Integer[])
  Mapper.resources(m, #{d == 1 ? 1 : 101}) { Mapper.resources(m, 0) { Array.push(Mapper.routes(m), -1) } }
  p(Mapper.routes(m))
S
