# ActiveModel::Attributes (types, defaults, casting, attribute_names, attributes), AttributeMethods (an
# alias, a custom suffix), Dirty (changes with an AttributeSet, and with plain accessors through
# *_will_change!) and Serializers::JSON (serializable_hash with only/except/methods, as_json, to_json, from_json).
gem "activemodel", "8.1.3"
require "active_model"
require_relative "attributes_decl"

class Product
  def attribute_present?(attr) = !attribute(attr).nil?
  def label = "#{name} x#{quantity}"
  def save
    changes_applied
    true
  end
end

class Person
  def first=(v)
    first_will_change! unless v == @first
    @first = v
  end
  def last=(v)
    last_will_change! unless v == @last
    @last = v
  end
  def attributes = { "first" => nil, "last" => nil }
  def save = changes_applied
end

puts("attributes:")
pr = Product.new(name: "Pen", price: "1.256", quantity: "3", released_on: "2026-10-20", weight: "2")
p([pr.name, pr.price.to_s, pr.quantity, pr.available, pr.released_on.to_s, pr.weight, pr.notes])
p(pr.attributes.keys)
p(Product.attribute_names)
p([Product.type_for_attribute(:price).type, Product.type_for_attribute("quantity").class.name, pr.attribute_names.size])
pr.quantity = "12abc"
pr.available = "0"
pr.notes = 42
p([pr.quantity, pr.available, pr.notes])
p(Product.new.quantity)

puts("alias and suffix:")
p([pr.name_present?, pr.notes_present?, Product.new.name_present?])

puts("dirty:")
d = Product.new(name: "Cup", quantity: 2)
d.save
p([d.changed?, d.changes])
d.name = "Mug"
d.quantity = "2"
p([d.changed?, d.changed, d.changes, d.name_changed?, d.quantity_changed?, d.name_was, d.name_change])
p([d.name_changed?(from: "Cup"), d.name_changed?(from: "Cup", to: "Mug"), d.name_changed?(to: "Tea")])
p(d.changed_attributes)
d.save
p([d.changed?, d.previous_changes, d.name_previously_changed?, d.name_previously_was, d.name_previous_change])
d.name = "Bowl"
d.restore_name!
p([d.name, d.changed?])
d.name = "Bowl"
d.clear_name_change
p([d.name, d.changed?])
d.quantity = 9
d.restore_attributes
p(d.quantity)
d.name = "Jar"
d.clear_changes_information
p([d.changed?, d.previous_changes])

puts("forced:")
pe = Person.new
pe.first = "Ko"
p([pe.changed?, pe.changes, pe.first_changed?, pe.first_was])
pe.save
pe.first = "Ichi"
p([pe.changes, pe.previous_changes, pe.first_previously_changed?])
pe.restore_attributes
p([pe.first, pe.changed?])
pe.first = "Taro"
p([pe.given, pe.given_changed?, pe.given_change, pe.given_was, Person.attribute_alias?(:given), Person.attribute_alias(:given)])

puts("validations:")
bad = Product.new(name: "", quantity: 0)
p([bad.valid?, bad.errors.full_messages])
num = Product.new(name: "N", quantity: "abc")
p([num.valid?, num.errors.full_messages, num.quantity])

puts("json:")
j = Product.new(name: "Box", price: "9.5", quantity: 4, released_on: "2026-01-02")
p(j.serializable_hash.transform_values(&:to_s))
p(j.serializable_hash(only: [:name, :quantity]))
p(j.serializable_hash(except: [:price, :weight, :notes, :released_on], methods: :label))
p(j.as_json(only: :name, root: true))
puts(j.to_json(only: [:name, :available, :released_on]))
k = Product.new.from_json('{"name":"Bag","quantity":7}')
p([k.name, k.quantity])
p(Person.new.tap { _1.first = "A" }.as_json)
