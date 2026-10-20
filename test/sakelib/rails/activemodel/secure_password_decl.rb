# The class bodies of secure_password.rb / secure_password.sake.
class User
  include ActiveModel::Model
  include ActiveModel::SecurePassword
  attr_accessor :name, :password_digest, :recovery_password_digest
  has_secure_password
  has_secure_password :recovery_password, validations: false
end
