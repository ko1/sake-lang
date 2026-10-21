# roundhouse's db/seed.sql writes seeds.rb's `password: "password"` into a `password` column, which the
# users table doesn't have (has_secure_password keeps password_digest). Writes a copy with a bcrypt digest.
# ruby seed_fix.rb SEED_SQL OUT_SQL
require "bcrypt"
src, out = ARGV.fetch(0), ARGV.fetch(1)
s = File.read(src)
fixed = s.sub("INSERT INTO users (id, email_address, password, ", "INSERT INTO users (id, email_address, password_digest, ")
         .sub("'one@example.com','password'", "'one@example.com','#{BCrypt::Password.create("password")}'")
abort "seed_fix.rb: the users INSERT in #{src} is not the expected one" if fixed == s || fixed.include?(" password, ")
File.write(out, fixed)
