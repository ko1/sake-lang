# Ruby's x.class.name, as Rails formats errors and keys with it.
module Shop
  class Order
    attr_reader :id
    def initialize(id) = @id = id
  end
  class RecordNotFound < StandardError
  end
end
Point = Struct.new(:x, :y)
values = [1, 2.5, 3r, "s", :sym, nil, true, false, [1, "a"], [1], {a: 1}, {}, Set.new, 1..2, /re/,
          Time.at(0), Point.new(1, 2), Shop::Order.new(1), Shop::RecordNotFound.new("gone"), KeyError.new("k")]
puts values.map { |v| v.class.name }.join(" ")
begin
  {}.fetch(:missing)
rescue => e
  puts "#{e.class.name}: #{e.message}"
end
