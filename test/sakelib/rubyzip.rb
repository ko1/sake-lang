require "zip"
require "base64"
require "tmpdir"

def t0 = Time.new(2024, 7, 1, 13, 5, 8)

def show(e)
  data = e.directory? ? "" : e.get_input_stream.read
  shown = data.bytesize > 40 ? "bytes=#{data.bytesize}" : "data=#{data.inspect}"
  puts "#{e.name}: size=#{e.size} compressed=#{e.compressed_size} method=#{e.compression_method} crc=#{e.crc.to_s(16)} time=#{e.time.strftime("%Y-%m-%d %H:%M:%S")} dir=#{e.directory?} ftype=#{e.ftype} #{shown}"
end

# An archive written by rubyzip 3.4.1 (zip64 extra fields, UTF-8 name, archive comment).
def fixture = "UEsDBC0AAAAIAKRo4VjjUT2N//////////8JABQAaGVsbG8udHh0AQAQABcAAAAAAAAACgAAAAAAAADLSM3JyVfIQCcBUEsDBC0AAAAAAKRo4VjPYiAZ//////////8FABQAcy50eHQBABAABQAAAAAAAAAFAAAAAAAAAHBsYWluUEsDBBQAAAAAAKRo4VgAAAAAAAAAAAAAAAAEAAkAZGlyL1VUBQABhKmCZlBLAwQtAAAACACkaOFYf4lUCP//////////CQAUAGRpci94LmJpbgEAEAADAAAAAAAAAAUAAAAAAAAAY2BkAgBQSwMELQAAAAgApGjhWA4K4Rb//////////w0AFADml6XmnKzoqp4udHh0AQAQAAcAAAAAAAAACQAAAAAAAADLy8zIz0vPBwBQSwECNAMtAAAACACkaOFY41E9jf//////////CQAUAAAAAAABAAAApIEAAAAAaGVsbG8udHh0AQAQABcAAAAAAAAACgAAAAAAAABQSwECNAMtAAAAAACkaOFYz2IgGf//////////BQAUAAAAAAABAAAApIFFAAAAcy50eHQBABAABQAAAAAAAAAFAAAAAAAAAFBLAQI0AxQAAAAAAKRo4VgAAAAAAAAAAAAAAAAEAAkAAAAAAAEAAADtQYEAAABkaXIvVVQFAAGEqYJmUEsBAjQDLQAAAAgApGjhWH+JVAj//////////wkAFAAAAAAAAQAAAKSBrAAAAGRpci94LmJpbgEAEAADAAAAAAAAAAUAAAAAAAAAUEsBAjQDLQAAAAgApGjhWA4K4Rb//////////w0AFAAAAAAAAQAAAKSB7AAAAOaXpeacrOiqni50eHQBABAABwAAAAAAAAAJAAAAAAAAAFBLBQYAAAAABQAFAGcBAAA0AQAABwBmaXh0dXJl"

puts "-- an archive written by rubyzip"
zf = Zip::File.open_buffer(Base64.decode64(fixture))
zf.each { |e| show(e) }
puts zf.entries.map(&:name).join(" ")
p zf.read("s.txt")
e = zf.find_entry("dir/x.bin")
puts e.nil? ? "none" : "found #{e.name}"
p zf.find_entry("nope")
puts zf.glob("dir/*").map(&:name).join(" ")
puts zf.glob("*.txt").map(&:name).join(" ")
puts zf.glob("**/*.bin").map(&:name).join(" ")
p zf.size

puts "-- round trip through a file"
Dir.mktmpdir do |d|
  path = File.join(d, "a.zip")
  dos = Zip::DOSTime.from_time(t0)
  Zip::File.open(path, create: true) do |w|
    w.get_output_stream("hello.txt", time: dos) { |f| f.write "hello hello hello hello" }
    w.get_output_stream("s.txt", compression_method: Zip::Entry::STORED, time: dos) { |f| f.write "plain" }
    w.mkdir("dir")
    w.find_entry("dir/").time = dos
    w.get_output_stream("dir/x.bin", time: dos) { |f| f.write "\x00\x01\x02".b }
    w.get_output_stream("big.txt", time: dos) { |f| f.write "abc " * 1000 }
    w.get_output_stream("日本語.txt", time: dos) { |f| f.write "nihongo" }
    w.get_output_stream("empty.txt", time: dos) { |f| f.write "" }
  end
  read = Zip::File.open(path)
  read.each { |e| show(e) }
  puts read.entries.map(&:name).join(" ")
  p read.read("s.txt")
  p read.read("big.txt") == "abc " * 1000
  p read.size

  puts "-- extract"
  out = File.join(d, "out")
  Dir.mkdir(out)
  read.each { |e| e.extract(destination_directory: out) }
  p Dir.glob("**/*", base: out).sort
  p File.read(File.join(out, "hello.txt"))
  p File.read(File.join(out, "dir/x.bin")) == "\x00\x01\x02".b

  puts "-- errors"
  begin
    read.read("nope")
  rescue Errno::ENOENT => e
    puts e.message
  end
end
begin
  Zip::File.open_buffer("garbage")
rescue Zip::Error => e
  puts e.message
end
