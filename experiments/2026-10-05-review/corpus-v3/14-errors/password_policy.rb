# Check password changes against a policy: composition, dictionary words (with leetspeak), history, and user data.
require "set"

class PolicyViolation < StandardError
  attr_reader :violations

  def initialize(message, violations)
    super(message)
    @violations = violations
  end
end

class User
  attr_reader :login, :full_name, :history

  def initialize(login, full_name, history)
    @login = login
    @full_name = full_name
    @history = history
  end
end

DICTIONARY = Set["password", "dragon", "monkey", "sunshine", "letmein", "football", "welcome"]

def unleet(s) = s.downcase.tr("4@310$5", "aaeioss")

def strength(pw)
  classes = [/[a-z]/, /[A-Z]/, /\d/, /[^A-Za-z0-9]/].count { |re| pw.match?(re) }
  score = pw.length * 4 + classes * 10 + pw.chars.uniq.size * 2
  score -= 20 if pw.match?(/(.)\1\1/)
  score -= 15 if pw.downcase.match?(/abc|bcd|123|234|345|qwe|wer/)
  score
end

def violations_for(user, pw)
  v = []
  v << "shorter than 10 characters" if pw.length < 10
  v << "longer than 64 characters" if pw.length > 64
  missing = []
  missing << "lowercase" unless pw.match?(/[a-z]/)
  missing << "uppercase" unless pw.match?(/[A-Z]/)
  missing << "digit" unless pw.match?(/\d/)
  v << "missing #{missing.join(", ")}" unless missing.empty?
  plain = unleet(pw)
  word = DICTIONARY.find { |w| plain.include?(w) }
  v << "contains dictionary word '#{word}'" if word
  v << "contains the login name" if plain.include?(user.login.downcase)
  parts = user.full_name.downcase.split(" ").select { |n| n.length >= 3 }
  hit = parts.find { |n| plain.include?(n) }
  v << "contains part of the full name (#{hit})" if hit
  v << "reuses one of the last 3 passwords" if user.history.last(3).include?(pw)
  v
end

def change_password(user, pw)
  v = violations_for(user, pw)
  raise PolicyViolation.new("#{v.size} policy violation(s)", v) unless v.empty?
  s = strength(pw)
  raise PolicyViolation.new("too weak", ["strength #{s} is below 70"]) if s < 70
  user.history << pw
  s
end

user = User.new("kenji", "Kenji Tanaka", ["Spring2024!x", "Summer2024!x", "Autumn2024!x", "Winter2024!x"])
attempts = [
  "short1A",
  "alllowercaseletters",
  "P@ssw0rd2026!",
  "MyKenjiPass99",
  "tanakaRules2026",
  "Summer2024!x",
  "Spring2024!x",
  "aaaBBB111ccc",
  "Abcdefgh1234",
  "Blue-Kettle-Rain-77",
  "Blue-Kettle-Rain-77"
]

accepted = 0
reasons = Hash.new(0)
attempts.each do |pw|
  s = change_password(user, pw)
  accepted += 1
  puts "#{pw.ljust(20)} accepted (strength #{s})"
rescue PolicyViolation => e
  puts "#{pw.ljust(20)} rejected: #{e.message}"
  e.violations.each do |msg|
    puts "    - #{msg}"
    reasons[msg.split(" ").first] += 1
  end
end
puts "accepted #{accepted} of #{attempts.size}; history size #{user.history.size}"
puts reasons.sort_by { |k, _| k }.map { |k, n| "#{k}:#{n}" }.join(" ")
