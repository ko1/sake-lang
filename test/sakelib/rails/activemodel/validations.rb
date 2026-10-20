# ActiveModel's validators: length, absence, numericality, format, inclusion/exclusion, acceptance,
# confirmation, comparison, a custom EachValidator (validates key) and Validator (validates_with), the
# validates_*_of helpers, validates! and except_on.
gem "activemodel", "8.1.3"
require "active_model"
require "date"
require "active_support/core_ext/object/inclusion"   # numericality in: (Rails apps have it loaded)

class UniquenessOfDomainValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, :taken, message: "has a taken domain") if value.to_s.end_with?("@taken.com")
  end
end

class PlanValidator < ActiveModel::Validator
  def validate(record)
    record.errors.add(:base, "Plan 3 needs a level") if record.plan == 3 && record.level.nil?
  end
end

require_relative "validations_decl"

def check(label, attrs, context = nil)
  s = Signup.new({ login: "kosaki", age: 20, terms: "1", limit: 10, level: 3 }.merge(attrs))
  ok = s.valid?(context)
  puts("#{label}: #{ok} #{s.errors.full_messages.inspect}")
  p(s.errors.details) unless ok
end

check("ok", {})
check("login short", { login: "ab" })
check("login long", { login: "abcdefghi" })
check("nickname", { nickname: "abc" })
check("pin", { pin: "12" })
check("pin letters", { pin: "12ab5" })
check("pin blank", { pin: "" })
check("bio limit", { bio: "x" * 11 })
check("code", { code: "x" })
check("age low", { age: 17 })
check("age high", { age: "121" })
check("age text", { age: "old" })
check("age nil", { age: nil })
check("score", { score: 11 })
check("count", { count: 2 })
check("count float", { count: 3.5 })
check("ratio", { ratio: 0 })
check("ratio string", { ratio: "1.5" })
check("level", { level: 4 })
check("email", { email: "nope" })
check("email taken", { email: "a@taken.com" })
check("size", { size: "XL" })
check("color", { color: "red" })
check("plan", { plan: 5 })
check("plan 3", { plan: 3, level: nil })
check("plan 3 level", { plan: 3, level: 3 })
check("terms", { terms: "0" })
check("terms nil", { terms: nil })
check("password", { password: "Secret", password_confirmation: "secret" })
check("password mismatch", { password: "Secret", password_confirmation: "other" })
check("dates", { starts_on: Date.new(2026, 10, 20), ends_on: Date.new(2026, 10, 19) })
check("dates ok", { starts_on: Date.new(2026, 10, 20), ends_on: Date.new(2026, 10, 21) })
check("no login", { login: nil })
check("draft", { level: nil }, :draft)
begin
  check("strict", { count: 101 })
rescue ActiveModel::StrictValidationFailed => e
  puts("strict: StrictValidationFailed #{e.message}")
end
p(Signup.validators_on(:count).map(&:kind))
p(Signup.validators_on(:email).map(&:class).map(&:name))
p(Signup.validators_on(:login).map { |v| [v.kind, v.options] })
