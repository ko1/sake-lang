class Message
  attr_reader :from, :rcpts, :lines

  def initialize(from, rcpts, lines)
    @from = from
    @rcpts = rcpts
    @lines = lines
  end
end

LOCAL_DOMAINS = ["example.org", "mail.example.org"]

class Session
  attr_reader :state, :client, :from, :rcpts, :data, :delivered, :errors

  def initialize
    @state = :connected
    @client = nil
    @delivered = []
    @errors = 0
    reset
  end

  def reset
    @from = nil
    @rcpts = []
    @data = []
  end

  def fail(code, text)
    @errors += 1
    "#{code} #{text}"
  end

  def address(arg, prefix)
    m = arg.match(/\A#{prefix}:\s*<([^<>@\s]+@([^<>\s]+))>\z/i)
    return nil if !m    
    [m[1], m[2].downcase]
  end

  def handle(line)
    if @state == :data
      if line == "."
        @delivered << Message.new(@from, @rcpts, @data)
        n = @data.size
        reset
        @state = :greeted
        return "250 OK: queued as #{@delivered.size} (#{n} lines)"
      end
      @data << (line.start_with?("..") ? line[1..] : line)
      return nil
    end
    verb, _sp, arg = line.partition(" ")
    verb = verb.upcase
    case verb
    in "HELO" | "EHLO"
      return fail(501, "domain required") if arg.empty?
      reset
      @client = arg
      @state = :greeted
      "250 hello #{arg}"
    in "MAIL"
      return fail(503, "send HELO first") if @state == :connected
      return fail(503, "nested MAIL") if @state != :greeted
      addr = address(arg, "FROM")
      return fail(501, "bad sender syntax") if !addr    
      @from = addr[0]
      @state = :mail
      "250 sender ok"
    in "RCPT"
      return fail(503, "need MAIL first") if @state != :mail && @state != :rcpt
      addr = address(arg, "TO")
      return fail(501, "bad recipient syntax") if !addr    
      email, domain = addr
      return fail(550, "relaying denied for #{domain}") unless LOCAL_DOMAINS.include?(domain)
      return fail(452, "too many recipients") if @rcpts.size >= 3
      @rcpts << email
      @state = :rcpt
      "250 recipient ok"
    in "DATA"
      return fail(503, "need RCPT first") if @state != :rcpt
      @state = :data
      "354 end with <CRLF>.<CRLF>"
    in "RSET"
      reset
      @state = :greeted if @state != :connected
      "250 reset"
    in "NOOP" then "250 ok"
    in "QUIT"
      @state = :closed
      "221 bye"
    else fail(500, "unknown command #{verb}")
    end
  end
end

transcripts = {
  "good" => ["EHLO client.test", "MAIL FROM:<ann@client.test>", "RCPT TO:<bob@example.org>",
             "RCPT TO:<cy@Mail.Example.org>", "DATA", "Subject: hi", "", "..leading dot", "bye", ".", "QUIT"],
  "rude" => ["MAIL FROM:<x@y.z>", "HELO", "HELO h", "RCPT TO:<a@example.org>", "MAIL FROM:bad",
             "MAIL FROM:<x@y.z>", "MAIL FROM:<x@y.z>", "RCPT TO:<spam@elsewhere.com>", "DATA", "VRFY bob", "QUIT"],
  "many" => ["HELO h", "MAIL FROM:<a@h>", "RCPT TO:<1@example.org>", "RCPT TO:<2@example.org>",
             "RCPT TO:<3@example.org>", "RCPT TO:<4@example.org>", "RSET", "NOOP", "MAIL FROM:<b@h>",
             "RCPT TO:<z@example.org>", "DATA", "one line", ".", "QUIT", "NOOP"]
}

transcripts.each do |name, lines|
  s = Session.new
  puts "== #{name}"
  lines.each do |line|
    if s.state == :closed
      puts "  C: #{line}   (connection closed)"
      next
    end
    reply = s.handle(line)
    puts(reply ? "  C: #{line}\n  S: #{reply}" : "  C: #{line}")
  end
  s.delivered.each do |m|
    puts "  delivered from #{m.from} to #{m.rcpts.join(", ")}: #{m.lines.inspect}"
  end
  puts "  errors: #{s.errors}, final state: #{s.state}"
end
