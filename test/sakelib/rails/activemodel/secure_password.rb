# ActiveModel::SecurePassword: has_secure_password (password=, authenticate, the digest's validations,
# confirmation, challenge, the 72-byte limit) on bcrypt.
gem "activemodel", "8.1.3"
begin
  require "bcrypt"
rescue LoadError
  # The bcrypt gem is not installed here: the same over String#crypt's $2b$ (as sakelib/bcrypt.sake does).
  require "securerandom"
  module BCrypt
    module Engine
      MIN_COST = 4
      def self.cost = 12
    end
    class Password < String
      def self.create(secret, cost:)
        alphabet = "./ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        salt = format("$2b$%02d$", cost) + Array.new(22) { alphabet[SecureRandom.random_number(64)] }.join
        new(secret.crypt(salt))
      end
      def salt = self[0, 29]
      def is_password?(secret) = secret.to_s.crypt(salt) == self
    end
  end
  $LOADED_FEATURES << "bcrypt.rb"
end
require "active_model"
require_relative "secure_password_decl"
ActiveModel::SecurePassword.min_cost = true

u = User.new(name: "ko1")
p([u.valid?, u.errors.full_messages])
u.password = "secret"
p([u.password, u.password_digest.start_with?("$2"), u.password_digest.size, u.valid?])
p([u.authenticate("wrong"), u.authenticate("secret") == u, u.authenticate_password("secret") == u])
p(u.password_salt == u.password_digest[0, 29])
u.password_confirmation = "other"
p([u.valid?, u.errors.full_messages])
u.password_confirmation = "secret"
p(u.valid?)
u.password_challenge = "nope"
p([u.valid?, u.errors.full_messages])
u.password_challenge = nil
u.password = "x" * 73
p([u.valid?, u.errors.full_messages, u.errors.details])
u.password = ""
p(u.password.size)
u.password = nil
p([u.password, u.password_digest, u.valid?])
u.recovery_password = "r3c0v3ry"
p([u.authenticate_recovery_password("r3c0v3ry") == u, u.authenticate_recovery_password("x")])
