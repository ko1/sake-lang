# Usage: ruby serve.rb <app> [port] [strict]   e.g. ruby serve.rb client_todo 18431 3
# A CGI-style server: each request runs `bin/sake --strict=<level> out/<app>.sake` with the raw request
# on stdin and sends its stdout back. Listens on 127.0.0.1 only. One request at a time.
require "socket"
require "open3"

app = ARGV[0] or abort("usage: ruby serve.rb <app> [port] [strict]")
port = Integer(ARGV[1] || 18431)
level = ARGV[2] || "3"
dir = __dir__
sake = File.expand_path("../../../bin/sake", dir)
program = File.join(dir, "out", "#{app}.sake")
abort("no #{program}; run ./build.sh first") unless File.exist?(program)
Dir.mkdir(File.join(dir, "data")) unless Dir.exist?(File.join(dir, "data"))

server = TCPServer.new("127.0.0.1", port)
$stderr.puts "serving #{app} on http://127.0.0.1:#{port}/ (pid #{Process.pid}, strict=#{level})"
trap("INT") { exit }
trap("TERM") { exit }

loop do
  client = server.accept
  begin
    head = +""
    while (line = client.gets)
      head << line
      break if line == "\r\n" || line == "\n"
    end
    next if head.empty?
    len = head[/^content-length:\s*(\d+)/i, 1].to_i
    body = len > 0 ? client.read(len).to_s : ""
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    out, err, status = Open3.capture3(sake, "--strict=#{level}", program, stdin_data: head + body, chdir: dir)
    ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000).round
    if status.success? && out.start_with?("HTTP/")
      client.write(out)
    else
      msg = "sake exited #{status.exitstatus}\n#{err}"
      client.write("HTTP/1.1 500 Internal Server Error\r\nContent-Type: text/plain\r\nContent-Length: #{msg.bytesize}\r\nConnection: close\r\n\r\n#{msg}")
    end
    $stderr.puts "#{head.lines.first.strip} -> #{out[/\AHTTP\/1.1 (\d+)/, 1] || 500} (#{ms} ms)"
  ensure
    client.close
  end
end
