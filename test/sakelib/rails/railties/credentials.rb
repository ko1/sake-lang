gem "activesupport", "8.1.3"
gem "railties", "8.1.3"
require "rails"
require "tmpdir"
require "fileutils"
require "yaml"
require_relative "fixtures/config/application"

# Credentials: Rails.application.credentials from config/credentials.yml.enc and config/master.key (a file
# `rails new` wrote), credentials:show and fetch, a new encrypted file written and read back, the errors of a
# missing or wrong key, RAILS_MASTER_KEY, and secret_key_base's lookup.
app = Rails.application
root = app.config.root.to_s
rel = ->(path) { path.to_s.delete_prefix(root + "/") }

puts "-- the application's credentials"
p Rails.env
p [rel.(app.config.credentials.content_path), rel.(app.config.credentials.key_path)]
credentials = app.credentials
p credentials.secret_key_base
p credentials.config.keys
p credentials.dig(:aws, :access_key_id)
p credentials.secret_key_base!.size
puts "-- credentials:show"
puts credentials.read.presence
puts "-- an encrypted file of our own"
dir = Dir.mktmpdir
key = ActiveSupport::EncryptedFile.generate_key
p key.size
File.write(File.join(dir, "test.key"), key)
mine = app.encrypted(File.join(dir, "test.yml.enc"), key_path: File.join(dir, "test.key"))
p mine.read
mine.write("aws:\n  access_key_id: AKIA123\n  secret_access_key: \"s3cr3t\"\nlist:\n  - 1\n  - two\nname: Säke\n")
p File.read(File.join(dir, "test.yml.enc")).count("-") >= 4
p mine.read
p mine.config
p mine.dig(:aws, :access_key_id)
p mine[:aws][:secret_access_key]
p mine.name
p mine.list
p YAML.load(mine.read).dig("aws", "access_key_id")
puts "-- change"
mine.change { |tmp| File.write(tmp, File.read(tmp) + "added: true\n") }
p app.encrypted(File.join(dir, "test.yml.enc"), key_path: File.join(dir, "test.key")).config[:added]
puts "-- errors"
wrong = ActiveSupport::EncryptedConfiguration.new(config_path: File.join(dir, "test.yml.enc"), key_path: "fixtures/config/master.key",
                                                  env_key: "NO_SUCH_KEY", raise_if_missing_key: false)
begin
  wrong.read
rescue ActiveSupport::MessageEncryptor::InvalidMessage => e
  puts "InvalidMessage: #{e.message}"
end
missing = ActiveSupport::EncryptedConfiguration.new(config_path: File.join(dir, "test.yml.enc"), key_path: File.join(dir, "none.key"),
                                                    env_key: "NO_SUCH_KEY", raise_if_missing_key: true)
begin
  missing.read
rescue ActiveSupport::EncryptedFile::MissingKeyError => e
  puts "MissingKeyError: #{e.message.sub(dir, "TMP")}"
end
nokey = app.encrypted(File.join(dir, "test.yml.enc"), key_path: File.join(dir, "none.key"))
p [nokey.key? != nil, nokey.read, nokey.config]
nofile = app.encrypted(File.join(dir, "none.yml.enc"), key_path: File.join(dir, "test.key"))
p [nofile.key? != nil, nofile.read, nofile.config]
short = ActiveSupport::EncryptedFile.new(content_path: File.join(dir, "short.enc"), key_path: File.join(dir, "short.key"),
                                         env_key: "NO_SUCH_KEY", raise_if_missing_key: true)
File.write(File.join(dir, "short.key"), "abc")
begin
  short.write("x")
rescue ActiveSupport::EncryptedFile::InvalidKeyLengthError => e
  puts "InvalidKeyLengthError: #{e.message}"
end
puts "-- RAILS_MASTER_KEY"
ENV["TEST_MASTER_KEY"] = key
from_env = app.encrypted(File.join(dir, "test.yml.enc"), key_path: File.join(dir, "none.key"), env_key: "TEST_MASTER_KEY")
p from_env.dig(:aws, :access_key_id)
ENV["TEST_MASTER_KEY"] = ""
p from_env.key? != nil
puts "-- secret_key_base"
p app.secret_key_base == credentials.secret_key_base
ENV["SECRET_KEY_BASE"] = "from the environment"
app.config.instance_variable_set(:@secret_key_base, nil)   # (memoized: a new process would look again)
p app.config.secret_key_base
ENV.delete("SECRET_KEY_BASE")
ENV["SECRET_KEY_BASE_DUMMY"] = "1"
app.config.root = dir
app.config.instance_variable_set(:@secret_key_base, nil)
s = app.config.secret_key_base
p [s.size, File.read(File.join(dir, "tmp/local_secret.txt")) == s]
ENV.delete("SECRET_KEY_BASE_DUMMY")
Rails.env = "production"
begin
  app.config.secret_key_base = nil
rescue ArgumentError => e
  puts "ArgumentError: #{e.message}"
end
begin
  app.config.secret_key_base = 42
rescue ArgumentError => e
  puts "ArgumentError: #{e.message}"
end
FileUtils.rm_rf(dir)
