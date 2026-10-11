require "net/smtp"
require "socket"
require "digest/md5"

# --- a tiny SMTP server: one connection per call, in a thread; the thread's value is what it heard ---
def reply(c, text) = c.write(text + "\r\n")

def auth_reply(c, ok) = reply(c, ok ? "235 2.7.0 Authentication successful" : "535 5.7.8 Authentication credentials invalid")

def b64(s) = s.unpack1("m")

def handle(c, mode, log)
  reply(c, "220 test.example ESMTP ready")
  while (line = c.gets)
    line = line.chomp
    log << line
    if line.start_with?("EHLO ")
      if mode == "helo_only"
        reply(c, "502 5.5.2 EHLO not supported")
      else
        reply(c, "250-test.example greets #{line[5..]}\r\n250-SIZE 1000000\r\n250-8BITMIME\r\n250-AUTH PLAIN LOGIN CRAM-MD5 XOAUTH2\r\n250 SMTPUTF8")
      end
    elsif line.start_with?("HELO ")
      reply(c, "250 test.example")
    elsif line.start_with?("MAIL FROM:")
      reply(c, line.include?("blocked") ? "553 5.7.1 Sender address rejected" : "250 2.1.0 Ok")
    elsif line.start_with?("RCPT TO:")
      if line.include?("nobody@")
        reply(c, "550 5.1.1 No such user")
      elsif line.include?("busy@")
        reply(c, "450 4.2.1 Mailbox busy, try later")
      else
        reply(c, "250 2.1.5 Ok")
      end
    elsif line == "DATA"
      reply(c, "354 End data with <CR><LF>.<CR><LF>")
      body = ""
      while (l = c.gets) && l != ".\r\n"
        body += l
      end
      log << "message: #{body.force_encoding("UTF-8").inspect}"
      reply(c, "250 2.0.0 Ok: queued as 42")
    elsif line.start_with?("AUTH PLAIN ")
      auth_reply(c, b64(line[11..]) == "\0alice\0s3cret")
    elsif line == "AUTH LOGIN"
      reply(c, "334 VXNlcm5hbWU6")
      user = b64(c.gets.chomp)
      reply(c, "334 UGFzc3dvcmQ6")
      pass = b64(c.gets.chomp)
      log << "login: #{user} #{pass}"
      auth_reply(c, user == "alice" && pass == "s3cret")
    elsif line == "AUTH CRAM-MD5"
      reply(c, "334 " + ["<1896.697170952@test.example>"].pack("m0"))
      log << "cram: #{b64(c.gets.chomp)}"
      auth_reply(c, true)
    elsif line.start_with?("AUTH XOAUTH2 ")
      log << "xoauth2: #{b64(line[13..]).inspect}"
      auth_reply(c, true)
    elsif line == "RSET" || line == "NOOP"
      reply(c, "250 2.0.0 Ok")
    elsif line == "QUIT"
      reply(c, "221 2.0.0 Bye")
      break
    else
      reply(c, "502 5.5.2 Error: command not recognized")
    end
  end
  log << "(closed)"
  c.close
  log
end

def serve(server, mode)
  Thread.new do
    c = server.accept
    handle(c, mode, [])
  end
end

def show(log) = log.each { |l| puts "  S| #{l}" }

server = TCPServer.new("127.0.0.1", 0)
port = server.addr[1]

msg = "Subject: hello\nFrom: alice@example.com\n\nHi Bob,\n.a line that starts with a dot\r\nbye"

# a session with a block: EHLO capabilities, one message to two recipients
th = serve(server, "normal")
result = Net::SMTP.start("127.0.0.1", port, "client.example") do |smtp|
  p [smtp.started?, smtp.esmtp?, smtp.capabilities]
  p [smtp.capable_auth_types, smtp.capable_plain_auth?, smtp.capable_cram_md5_auth?, smtp.capable_starttls?, smtp.capable?("SIZE")]
  res = smtp.send_message(msg, "alice@example.com", "bob@example.com", "carol@example.com")
  p [res.status, res.string, res.success?, res.message]
  smtp.rset.status
end
p result
show(th.value)

# EHLO refused: the client falls back to HELO
th = serve(server, "helo_only")
Net::SMTP.start("127.0.0.1", port, "old.example") do |smtp|
  p [smtp.esmtp?, smtp.capabilities, smtp.capable?("SIZE"), smtp.capable_auth_types]
  smtp.send_message("", "a@example.com", "b@example.com")
end
show(th.value)

# authentication: PLAIN, LOGIN, CRAM-MD5, XOAUTH2
[:plain, :login, :cram_md5, :xoauth2].each do |authtype|
  th = serve(server, "normal")
  Net::SMTP.start("127.0.0.1", port, "client.example", "alice", "s3cret", authtype) do |smtp|
    p [authtype, smtp.started?]
  end
  show(th.value)
end

# bad credentials: SMTPAuthenticationError, and the connection is closed without QUIT
th = serve(server, "normal")
begin
  Net::SMTP.start("127.0.0.1", port, "client.example", "alice", "wrong", :plain) { |smtp| p smtp }
rescue Net::SMTPAuthenticationError => e
  p [e.message, e.response.status]
end
show(th.value)

# server errors in a session: 5xx, 4xx; after an error QUIT is not sent
th = serve(server, "normal")
begin
  Net::SMTP.start("127.0.0.1", port) do |smtp|
    smtp.send_message(msg, "alice@example.com", "nobody@example.com")
  end
rescue Net::SMTPFatalError => e
  p [e.message, e.response.status, e.response.string]
end
show(th.value)
th = serve(server, "normal")
begin
  Net::SMTP.start("127.0.0.1", port) do |smtp|
    smtp.send_message(msg, "alice@example.com", "busy@example.com")
  end
rescue Net::SMTPServerBusy => e
  p [e.message, e.response.status]
end
show(th.value)
th = serve(server, "normal")
begin
  Net::SMTP.start("127.0.0.1", port) do |smtp|
    smtp.send_message(msg, "blocked@example.com", "bob@example.com")
  end
rescue Net::SMTPFatalError => e
  p [e.message, e.response.status]
end
show(th.value)

# without a block: new, start, the commands one by one, a message stream, finish
th = serve(server, "normal")
smtp = Net::SMTP.new("127.0.0.1", port)
p [smtp.address, smtp.port == port, smtp.started?, smtp.tls?, smtp.starttls?, smtp.esmtp?, smtp.capabilities]
smtp.start("streams.example")
p smtp.started?
p smtp.mailfrom("alice@example.com").string
p smtp.rcptto("bob@example.com").string
begin
  smtp.mailfrom("evil@example.com\r\nRCPT TO:<x@example.com>")
rescue ArgumentError => e
  p e.message
end
p smtp.rset.status
res = smtp.open_message_stream("alice@example.com", "bob@example.com") do |f|
  f.puts "Subject: stream"
  f.puts
  f.print "line 1\nline 2\n"
  f << ".hidden\n"
  f.printf("%d items\n", 3)
end
p res.status
p smtp.send_message("Subject: ünïcode\n\nhi", "alice@example.com", "bøb@example.com").status
smtp.finish
p smtp.started?
show(th.value)
begin
  smtp.finish
rescue IOError => e
  p e.message
end
begin
  smtp.send_message(msg, "a@example.com", "b@example.com")
rescue IOError => e
  p e.message
end

# argument errors before connecting
begin
  Net::SMTP.start("127.0.0.1", port, "client.example", "alice", nil, :plain) { |smtp| p smtp }
rescue ArgumentError => e
  p e.message
end
begin
  Net::SMTP.start("127.0.0.1", port, "client.example", "alice", "s3cret", :foo) { |smtp| p smtp }
rescue ArgumentError => e
  p e.message
end

# a connection refused: the port is closed now
server.close
begin
  Net::SMTP.start("127.0.0.1", port) { |smtp| p smtp }
rescue SystemCallError, IOError => e
  puts "connection failed"
end

# replies and addresses on their own
res = Net::SMTP::Response.parse("250-mail.example\n250-AUTH LOGIN PLAIN\n250 8BITMIME\n")
p [res.status, res.success?, res.continue?, res.status_type_char, res.message, res.capabilities]
res = Net::SMTP::Response.parse("334 PDE4OTYuNjk3MTcwOTUyQHBvc3RvZmZpY2UucmVzdG9uLm1jaS5uZXQ+\n")
p [res.continue?, res.cram_md5_challenge, res.capabilities]
addr = Net::SMTP::Address.new("ü@example.com", "SMTPUTF8", "SMTPUTF8")
p [addr.address, addr.parameters, addr.to_s]
p [Net::SMTP.default_port, Net::SMTP.default_submission_port, Net::SMTP.default_tls_port, Net::SMTP.default_ssl_port]
p Net::SMTP.new("mail.example.com").inspect
