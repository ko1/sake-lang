class Request
  attr_accessor :method, :path, :version, :headers, :body

  def initialize
    @method = ""
    @path = ""
    @version = ""
    @headers = {}
    @body = +""
  end
end

class HttpError < StandardError
  attr_reader :state

  def initialize(message, state)
    super(message)
    @state = state
  end
end

class HttpParser
  attr_reader :state, :buffer, :request, :remaining, :done

  def initialize
    @state = :request_line
    @buffer = +""
    @request = Request.new
    @remaining = 0
    @done = []
  end

  def take_line
    idx = @buffer.index("\r\n")
    return nil if idx.nil?
    line = @buffer[0...idx]
    @buffer = @buffer[(idx + 2)..]
    line
  end

  def finish
    @done << @request
    @request = Request.new
    @state = :request_line
  end

  def feed(chunk)
    @buffer += chunk
    progress = true
    progress = step while progress
  end

  def step
    case @state
    in :request_line
      line = take_line
      return false if line.nil?
      return true if line == ""
      parts = line.split(" ")
      raise HttpError.new("bad request line: #{line}", @state) if parts.size != 3
      m, path, version = parts
      raise HttpError.new("bad version #{version}", @state) unless version.start_with?("HTTP/1.")
      @request.method = m
      @request.path = path
      @request.version = version
      @state = :headers
      true
    in :headers
      line = take_line
      return false if line.nil?
      headers = @request.headers
      if line == ""
        if headers["transfer-encoding"] == "chunked"
          @state = :chunk_size
        else
          @remaining = headers.fetch("content-length", "0").to_i
          if @remaining == 0
            finish
          else
            @state = :body
          end
        end
        return true
      end
      name, sep, value = line.partition(":")
      raise HttpError.new("bad header: #{line}", @state) if sep == ""
      headers[name.strip.downcase] = value.strip
      true
    in :body
      return false if @buffer.empty?
      piece = @buffer[0...@remaining]
      @buffer = @buffer[piece.size..]
      @request.body += piece
      @remaining -= piece.size
      finish if @remaining == 0
      true
    in :chunk_size
      line = take_line
      return false if line.nil?
      raise HttpError.new("bad chunk size #{line.inspect}", @state) unless line.match?(/\A[0-9a-fA-F]+\z/)
      @remaining = line.hex
      @state = @remaining == 0 ? :trailer : :chunk_data
      true
    in :chunk_data
      return false if @buffer.size < @remaining + 2
      @request.body += @buffer[0...@remaining]
      raise HttpError.new("missing CRLF after chunk", @state) if @buffer[@remaining...(@remaining + 2)] != "\r\n"
      @buffer = @buffer[(@remaining + 2)..]
      @state = :chunk_size
      true
    in :trailer
      line = take_line
      return false if line.nil?
      finish if line == ""
      true
    end
  end
end

def slices(s, n)
  out = []
  i = 0
  while i < s.size
    out << s[i...(i + n)]
    i += n
  end
  out
end

stream = "GET /index.html HTTP/1.1\r\nHost: example.com\r\nAccept: */*\r\n\r\n" +
  "POST /api/items HTTP/1.1\r\nHost: example.com\r\nContent-Type: application/json\r\nContent-Length: 26\r\n\r\n{\"name\":\"widget\",\"qty\":3}\n" +
  "PUT /upload HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n5\r\nhello\r\n7\r\n, world\r\nA\r\n from Sake\r\n0\r\n\r\n" +
  "DELETE /items/7 HTTP/1.0\r\n\r\n"

[7, 64].each do |size|
  hp = HttpParser.new
  slices(stream, size).each { |chunk| hp.feed(chunk) }
  reqs = hp.done
  puts "chunk size #{size}: #{reqs.size} requests, parser #{hp.state}, leftover #{hp.buffer.size}"
  reqs.each do |r|
    puts "  #{r.method} #{r.path} #{r.version} headers=#{r.headers.keys.sort.join(",")}"
    puts "    body=#{r.body.inspect}" unless r.body.empty?
  end
end

["GET /\r\n\r\n", "GET / HTTP/2\r\n\r\n", "GET / HTTP/1.1\r\nNoColon\r\n\r\n", "PUT / HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\nzz\r\n"].each do |bad|
  hp = HttpParser.new
  begin
    hp.feed(bad)
    puts "unexpected success"
  rescue HttpError => e
    puts "error in #{e.state}: #{e.message}"
  end
end
