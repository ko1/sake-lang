# ActiveModel::Model: attribute assignment, naming, conversion, validations (validates, validate, contexts,
# conditions, strict), errors (messages, details, full messages, add/where/delete), validate! and i18n.
gem "activemodel", "8.1.3"
require "active_model"
require_relative "model_decl"

class Person
  def not_reserved
    errors.add(:name, :reserved, message: "is reserved") if name == "root"
  end
  def guest? = role == "guest"
  def persisted? = !id.nil?
end

puts("assign:")
pe = Person.new(name: "Ann", "email" => "ann@example.com", age: 3)
p([pe.name, pe.email, pe.age, pe.role])
pe.assign_attributes(role: "admin")
p(pe.role)
begin
  Person.new(nope: 1)
rescue ActiveModel::UnknownAttributeError => e
  puts("UnknownAttributeError: #{e.message}")
end
p(pe.slice(:name, :age))
p(pe.values_at(:name, :role))

puts("naming:")
n = Person.model_name
p([n.name, n.singular, n.plural, n.element, n.collection, n.param_key, n.route_key, n.singular_route_key, n.i18n_key, n.human])
p([Admin.model_name.name, Admin.model_name.route_key, Admin.lookup_ancestors.map(&:name)])
p([Tag.model_name.human, ActiveModel::Naming.plural(pe), ActiveModel::Naming.param_key(pe), ActiveModel::Naming.uncountable?(pe)])
p([Person.human_attribute_name("email"), Person.human_attribute_name(:created_at), Person.i18n_scope])

puts("conversion:")
p([pe.to_model == pe, pe.to_key, pe.to_param, pe.persisted?, pe.to_partial_path])
pe.id = 7
p([pe.to_key, pe.to_param, pe.persisted?])
pe.id = nil

puts("valid:")
p([pe.valid?, pe.invalid?, pe.errors.empty?, pe.errors.size])
bad = Person.new(name: "", email: "nope", age: -1)
p(bad.valid?)
p(bad.errors.full_messages)
p(bad.errors.messages)
p(bad.errors.details)
p(bad.errors[:name])
p(bad.errors[:nothing])
p([bad.errors.include?(:email), bad.errors.key?(:role), bad.errors.attribute_names])
p([bad.errors.added?(:name, :blank), bad.errors.added?(:age, :greater_than_or_equal_to, count: 0), bad.errors.of_kind?(:email, :invalid)])
p(bad.errors.full_messages_for(:age))
p(bad.errors.where(:name).map(&:type))
p(bad.errors.to_hash(true))
p(bad.errors.as_json(full_messages: true))
p(bad.errors.first.full_message)
p(bad.errors.map(&:attribute))

puts("numbers:")
Array["12", "1.5", "abc", 4.0, "0x1A", nil].each do |a|
  x = Person.new(name: "N", age: a)
  x.valid?
  p([a, x.errors[:age]])
end

puts("length:")
long = Person.new(name: "abcdefghijkl")
long.valid?
p(long.errors.full_messages)

puts("custom validate:")
root = Person.new(name: "root")
p([root.valid?, root.errors.full_messages, root.errors.details])

puts("context:")
r = Person.new(name: "Bo", role: "boss")
p([r.valid?, r.valid?(:create), r.errors.full_messages, r.validation_context])
p(r.valid?([:create, :special]))

puts("condition:")
g = Person.new(name: "G", role: "guest", id: 3)
p([g.valid?, g.errors.full_messages])
g.role = "member"
p(g.valid?)

puts("subclass:")
a = Admin.new(name: "Al")
p([a.valid?, a.errors.full_messages, Admin.validators_on(:level).map(&:kind), Person.validators_on(:level).map(&:kind)])
p(Person.validators.map(&:kind))
p(Person.validators_on(:name, :email).map { |v| [v.kind, v.options] })

puts("errors API:")
e = Person.new(name: "E").errors
e.add(:name, :too_short, count: 5)
e.add(:base, "Something is off")
e.add(:email, "is weird")
p(e.full_messages)
p(e.details)
p(e.delete(:email))
p([e.size, e.count, e.any?, e.to_a])
p(e.generate_message(:name, :blank))
p(e.full_message(:name, "is fine"))
p(e.inspect.include?("ActiveModel::Errors"))
e.clear
p(e.empty?)

puts("strict:")
begin
  Person.new(name: "S").errors.add(:name, :invalid, strict: true)
rescue ActiveModel::StrictValidationFailed => err
  puts("StrictValidationFailed: #{err.message}")
end

puts("validate!:")
begin
  Person.new(name: "").validate!
rescue ActiveModel::ValidationError => err
  puts("ValidationError: #{err.message}")
  p(err.model.name)
end

puts("i18n:")
I18n.backend.store_translations(:en, activemodel: {
  models: { person: "Human" },
  attributes: { person: { name: "Full name" } },
  errors: { models: { person: { attributes: { email: { invalid: "looks wrong" } } } } }
})
p([Person.model_name.human, Person.human_attribute_name(:name), Admin.human_attribute_name(:name)])
x = Person.new(name: "", email: "bad")
x.valid?
p(x.errors.full_messages)
