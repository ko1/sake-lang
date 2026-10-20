gem "activesupport", "8.1.3"
require "active_support"
require "active_support/json"
require "active_support/time"

# ActiveSupport::JSON (json/encoding, json/decoding) and as_json (core_ext/object/json)
class Point
  attr_reader :x, :y
  def initialize(x, y) = (@x, @y = x, y)
  def as_json(options = nil) = { "x" => @x, "y" => @y }
end

tokyo = Time.find_zone!("Tokyo")
data = { :id => 1, "name" => "<b>Ann & Bob</b>", :tags => [:a, "b"], :score => 1.5, :nan => Float::NAN, :none => nil,
         :ok => true, 2 => "two", :at => Time.utc(2024, 1, 2, 3, 4, 5), :zoned => tokyo.local(2024, 1, 2, 3, 4, 5),
         :day => Date.new(2024, 1, 2), :wait => 5.minutes, :range => 1..3, :set => Set[1, 2], :pt => Point.new(1, 2), :rat => Rational(1, 3) }
puts(ActiveSupport::JSON.encode(data))
puts(ActiveSupport::JSON.encode(data, escape: false))
puts(ActiveSupport::JSON.encode("  line separator"), ActiveSupport::JSON.encode([]), ActiveSupport::JSON.encode(nil))
p({ a: [1, :b] }.as_json, Time.utc(2024, 1, 2).as_json, Point.new(3, 4).as_json)
puts({ html: "<script>" }.to_json)
decoded = ActiveSupport::JSON.decode("{\"a\":[1,2.5,\"x\",null,true],\"b\":{\"c\":\"d\"}}")
p(decoded)
begin
  ActiveSupport::JSON.decode("{bad json")
rescue ActiveSupport::JSON.parse_error
  puts("parse error")
end
