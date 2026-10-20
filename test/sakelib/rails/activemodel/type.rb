gem "activemodel", "8.1.3"
require "active_model"

# ActiveModel::Type: cast (user input), serialize (to the database), deserialize (from it)
i = ActiveModel::Type::Integer.new
p([i.type, i.cast("42"), i.cast("4x"), i.cast(3.9), i.cast(true), i.cast(""), i.cast(nil), i.serialize("12"), i.serialize("abc"), i.deserialize("7")])
begin
  i.serialize(2**40)
rescue ActiveModel::RangeError => e
  puts("RangeError: #{e.message}")
end
p([ActiveModel::Type::Integer.new(limit: 8).serialize(2**40), ActiveModel::Type::BigInteger.new.serialize(2**70)])
s = ActiveModel::Type::String.new
p([s.type, s.cast(12), s.cast(true), s.cast(false), s.cast(:sym), s.serialize(1.5), s.serialize(false), s.changed_in_place?("a", "b"), s.mutable?])
p(ActiveModel::Type::ImmutableString.new(true: "1", false: "0").cast(true))
b = ActiveModel::Type::Boolean.new
p([b.type, b.cast("1"), b.cast("0"), b.cast("f"), b.cast("off"), b.cast("yes"), b.cast(""), b.cast(nil), b.cast(0), b.serialize("false")])
f = ActiveModel::Type::Float.new
p([f.type, f.cast("1.5"), f.cast(2), f.cast("Infinity"), f.cast(""), f.cast(true)])
d = ActiveModel::Type::Decimal.new(precision: 5, scale: 2)
p([d.type, d.cast("3.14159").to_s, d.cast(2).to_s, d.cast("junk").to_s])
dt = ActiveModel::Type::DateTime.new
p([dt.type, dt.cast("2026-10-20 12:34:56"), dt.cast("2026-10-20T12:34:56.123456Z"), dt.cast("2026-10-20 12:34:56+09:00"), dt.cast(""), dt.cast("garbage")])
p(dt.cast({1 => 2026, 2 => 10, 3 => 20}))
p(ActiveModel::Type::DateTime.new(precision: 0).cast(Time.utc(2026, 1, 2, 3, 4, 5.75r)))
da = ActiveModel::Type::Date.new
p([da.type, da.cast("2026-10-20"), da.cast("2026-02-30"), da.cast(Time.utc(2026, 1, 2, 3, 4, 5)), da.cast({1 => 2026, 2 => 3, 3 => 4})])
t = ActiveModel::Type::Time.new
p([t.type, t.cast("12:34:56"), t.cast("2026-10-20 01:02:03")])
bin = ActiveModel::Type::Binary.new
data = bin.serialize("ab\x00")
data => ActiveModel::Type::Binary::Data
p([bin.type, bin.binary?, data.to_s, data.hex, bin.cast(data)])
p([ActiveModel::Type.lookup(:integer).type, ActiveModel::Type.lookup(:string, limit: 10).limit, ActiveModel::Type.default_value.cast(:x)])
begin
  ActiveModel::Type.lookup(:nope)
rescue ArgumentError => e
  puts("ArgumentError: #{e.message}")
end

# ActiveModel::Attribute: a value before and after its cast
a = ActiveModel::Attribute.from_user("age", "42", ActiveModel::Type::Integer.new)
p([a.name, a.value_before_type_cast, a.value, a.value_for_database, a.came_from_user?])
a2 = a.with_value_from_user("43")
p([a2.value, a2.changed?, a2.original_value])
db = ActiveModel::Attribute.from_database("on", 1, ActiveModel::Type::Boolean.new)
p([db.value, db.value_for_database, db.changed?, db.came_from_user?])
p(ActiveModel::Attribute.with_cast_value("x", 5, ActiveModel::Type::String.new).value)
