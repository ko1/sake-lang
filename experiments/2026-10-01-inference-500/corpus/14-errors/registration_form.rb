# Validate user registration submissions and accumulate every error per form.
require "set"

class Submission
  attr_reader :username, :email, :age, :password, :confirm, :country

  def initialize(username, email, age, password, confirm, country)
    @username = username
    @email = email
    @age = age
    @password = password
    @confirm = confirm
    @country = country
  end
end

class FieldError
  attr_reader :field, :message

  def initialize(field, message)
    @field = field
    @message = message
  end
end

ALLOWED_COUNTRIES = Set["JP", "US", "DE", "FR", "BR"]
RESERVED_NAMES = ["admin", "root", "system"]

module Rules
  module_function

  def username(s, errors)
    name = s.username
    if name.strip.empty?
      errors << FieldError.new("username", "is required")
      return
    end
    len = name.length
    if len < 3 || len > 12
      errors << FieldError.new("username", "must be 3-12 characters (got #{len})")
    end
    unless name.match?(/\A[a-z][a-z0-9_]*\z/)
      errors << FieldError.new("username", "may contain only lowercase letters, digits and _")
    end
    errors << FieldError.new("username", "is reserved") if RESERVED_NAMES.include?(name.downcase)
  end

  def email(s, errors)
    parts = s.email.split("@")
    if parts.size != 2
      errors << FieldError.new("email", "must contain exactly one @")
      return
    end
    local, domain = parts
    errors << FieldError.new("email", "local part is empty") if local.empty?
    errors << FieldError.new("email", "domain needs a dot") unless domain.include?(".")
  end

  def age(s, errors)
    raw = s.age
    value = Integer(raw) rescue nil
    if value.nil?
      errors << FieldError.new("age", "is not a number: #{raw}")
    elsif value < 13
      errors << FieldError.new("age", "must be at least 13")
    elsif value > 120
      errors << FieldError.new("age", "looks wrong (#{value})")
    end
  end

  def password(s, errors)
    pw = s.password
    missing = []
    missing << "a digit" unless pw.match?(/\d/)
    missing << "an uppercase letter" unless pw.match?(/[A-Z]/)
    missing << "8 characters" if pw.length < 8
    errors << FieldError.new("password", "needs #{missing.join(", ")}") unless missing.empty?
    errors << FieldError.new("confirm", "does not match password") if pw != s.confirm
  end

  def country(s, errors)
    c = s.country.upcase
    errors << FieldError.new("country", "#{c} is not supported") unless ALLOWED_COUNTRIES.include?(c)
  end
end

def validate(s)
  errors = []
  Rules.username(s, errors)
  Rules.email(s, errors)
  Rules.age(s, errors)
  Rules.password(s, errors)
  Rules.country(s, errors)
  errors
end

submissions = [
  Submission.new("alice_01", "alice@example.com", "29", "Secret123", "Secret123", "jp"),
  Submission.new("Bob", "bob-at-example.com", "x9", "short", "shorter", "uk"),
  Submission.new("admin", "admin@localhost", "8", "Password1", "Password1", "us"),
  Submission.new("   ", "@example.org", "130", "lowercase1", "lowercase1", "de"),
  Submission.new("carol", "carol@mail.example", "45", "Carol2026!", "Carol2026!", "br")
]

by_field = Hash.new(0)
accepted = 0
submissions.each_with_index do |s, i|
  errors = validate(s)
  if errors.empty?
    accepted += 1
    puts "##{i + 1} #{s.username}: OK"
  else
    puts "##{i + 1} #{s.username.strip}: #{errors.size} error(s)"
    errors.each do |e|
      puts "    #{e.field} #{e.message}"
      by_field[e.field] += 1
    end
  end
end
puts "accepted #{accepted}/#{submissions.size}"
by_field.sort_by { |f, n| [-n, f] }.each do |f, n|
  puts format("%-9s %d", f, n)
end
