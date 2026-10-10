require_relative "ref/ini"

text = <<~INI
  ; a comment
  name = top level
  # another comment

  [server]
  host = example.com
  port = 8080
  ratio = 0.75
  debug = true
  quiet = false
  path = "/var/www\\tdocs"
  note = hello ; trailing comment
  [ database ]
  user=admin
  pass = "s3cr;et"
  empty =
  version = -3
INI

ini = IniFile.new(content: text)
p(ini.sections)
p(ini["global"])
p(ini["server"])
p(ini["database"])
p(ini["server"]["port"])
p(ini.has_section?("server"))
p(ini.has_section?("nope"))
p(ini["missing"])
p(ini.has_section?("missing"))

puts("== each")
ini.each { |s, k, v| puts("#{s}.#{k} = #{v.inspect}") }
ini.each_section { |s| puts("section #{s}") }

puts("== match")
p(ini.match(/^s/).keys)

puts("== write")
ini["new"] = { "a" => 1, "b" => "two\nlines" }
ini["server"]["port"] = 9090
p(ini.delete_section("missing"))
puts(ini.to_s)

puts("== merge")
other = IniFile.new(content: "[server]\nport = 1\nextra = yes\n[more]\nk = v\n")
merged = ini.merge(other)
p(merged.sections)
p(merged["server"])
p(ini["server"]["port"])
p(other.to_h)

puts("== options")
alt = IniFile.new(content: "x: 1\n// c\n[s]\ny: two\n", parameter: ":", comment: "/", default: "root")
p(alt.to_h)
puts(alt.to_s)

puts("== files")
path = "ini_test_tmp.ini"
ini.write(filename: path)
back = IniFile.load(path)
if back
  p(back.filename)
  p(back.to_h == ini.to_h)
  back.filename = path
  back.write
end
File.delete(path)
p(IniFile.load("no_such_file.ini"))

puts("== errors")
["just text", "= value", "[s]\nk = \"open"].each do |bad|
  begin
    IniFile.new(content: bad)
  rescue IniFile::Error => e
    puts("IniFile::Error: #{e.message}")
  end
end
begin
  IniFile.new(content: "a=1").write
rescue IniFile::Error => e
  puts("IniFile::Error: #{e.message}")
end
