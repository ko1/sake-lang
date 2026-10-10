require "dotenv"
require "tmpdir"

# Keys are prefixed so that the surrounding environment cannot have them.
ENV.keys.select { |k| k.start_with?("SAKE_DOTENV_") }.each { |k| ENV.delete(k) }
ENV.delete("DOTENV_LINEBREAK_MODE")

puts("-- Dotenv::Parser.call")
text = "# comment\n" +
  "SAKE_DOTENV_A=1\n" +
  "export SAKE_DOTENV_B=two words # trailing\n" +
  "SAKE_DOTENV_C=\"dq \\n x \\\"q\\\" $SAKE_DOTENV_A ${SAKE_DOTENV_B}\"\n" +
  "SAKE_DOTENV_D='sq \\n $SAKE_DOTENV_A'\n" +
  "SAKE_DOTENV_E=${SAKE_DOTENV_A}-$SAKE_DOTENV_B-${SAKE_DOTENV_NOPE}\n" +
  "SAKE_DOTENV_F=\\$SAKE_DOTENV_A\n" +
  "SAKE_DOTENV_G=\"a\\\\b\"\n" +
  "SAKE_DOTENV_H=$(echo hi)\n" +
  "SAKE_DOTENV_I=\"x\\ty\"\n" +
  "SAKE_DOTENV_J=\n" +
  "export SAKE_DOTENV_A\n" +
  "SAKE_DOTENV_L: colon\n" +
  "SAKE_DOTENV.M=dot\n" +
  "\n   \n" +
  "SAKE_DOTENV_N = spaced \n" +
  "SAKE_DOTENV_O=\"multi\nline\"\n" +
  "SAKE_DOTENV_P='it''s'\n"
h = Dotenv::Parser.call(text)
h.each { |k, v| puts("#{k}=#{v.inspect}") }
p(h.size)

puts("-- errors")
begin
  Dotenv::Parser.call("export SAKE_DOTENV_Z")
rescue Dotenv::FormatError => e
  puts("Dotenv::FormatError: #{e.message}")
end
p(Dotenv.load("/nonexistent/.env"))
begin
  Dotenv.load!("/nonexistent/.env")
rescue Errno::ENOENT => e
  puts("IOError")
end
begin
  Dotenv.require_keys("SAKE_DOTENV_NOPE1", "SAKE_DOTENV_NOPE2")
rescue Dotenv::MissingKeys => e
  puts("Dotenv::MissingKeys: #{e.message}")
end

puts("-- existing values")
ENV["SAKE_DOTENV_T"] = "old"
p(Dotenv::Parser.call("SAKE_DOTENV_T=new"))
p(Dotenv::Parser.call("SAKE_DOTENV_T=new", overwrite: true))
p(Dotenv.update({"SAKE_DOTENV_T" => "x", "SAKE_DOTENV_U" => "y"}))
p(ENV["SAKE_DOTENV_T"])
p(Dotenv.update({"SAKE_DOTENV_T" => "x"}, overwrite: true))
p(ENV["SAKE_DOTENV_T"])
p(Dotenv.modify({"SAKE_DOTENV_T" => "in", "SAKE_DOTENV_V" => "v"}) { [ENV["SAKE_DOTENV_T"], ENV["SAKE_DOTENV_V"]] })
p([ENV["SAKE_DOTENV_T"], ENV["SAKE_DOTENV_V"]])
p(Dotenv.require_keys("SAKE_DOTENV_T", "SAKE_DOTENV_U"))

puts("-- files")
Dir.mktmpdir do |dir|
  env = File.join(dir, ".env")
  local = File.join(dir, ".env.local")
  File.write(env, "SAKE_DOTENV_HOST=example.com\nSAKE_DOTENV_URL=\"https://$SAKE_DOTENV_HOST/${SAKE_DOTENV_T}\"\nSAKE_DOTENV_T=from-file\n")
  File.write(local, "SAKE_DOTENV_HOST=localhost\nSAKE_DOTENV_PORT=3000\n")
  p(Dotenv.parse(env))
  p(Dotenv.parse(env, local))
  p(Dotenv.parse(env, local, overwrite: true))
  p(Dotenv.load(env))
  p([ENV["SAKE_DOTENV_HOST"], ENV["SAKE_DOTENV_URL"], ENV["SAKE_DOTENV_T"]])
  p(Dotenv.load(local))
  p(ENV["SAKE_DOTENV_HOST"])
  p(Dotenv.overload(local))
  p([ENV["SAKE_DOTENV_HOST"], ENV["SAKE_DOTENV_PORT"]])
  p(Dotenv.overwrite(env))
  p(ENV["SAKE_DOTENV_T"])
  p(Dotenv.load(env, local, "/nonexistent"))
  begin
    Dotenv.overload!(env, "/nonexistent")
  rescue Errno::ENOENT => e
    puts("IOError")
  end
end

puts("-- legacy line breaks")
ENV["DOTENV_LINEBREAK_MODE"] = "legacy"
p(Dotenv::Parser.call("SAKE_DOTENV_W=\"a\\nb\\rc\""))
ENV.delete("DOTENV_LINEBREAK_MODE")
p(Dotenv::Parser.call("DOTENV_LINEBREAK_MODE=legacy\nSAKE_DOTENV_W=\"a\\nb\""))
p(Dotenv::Parser.call("SAKE_DOTENV_W=\"a\\nb\""))
puts("end")
