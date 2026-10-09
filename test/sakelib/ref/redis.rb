# Reference implementation of the redis gem's client (redis-rb 5) in plain Ruby, for test/sakelib/redis.rb
# (the gem is not installed). RESP2 over a TCPSocket; the commands the Sake port has, with the gem's reply
# conversions (get -> String or nil, incr -> Integer, hgetall -> Hash, expire -> true/false); pipelined and
# multi collect the replies of the commands called on the yielded PipelinedConnection.

require "socket"

class Redis
  class CommandError < StandardError; end
  class CannotConnectError < StandardError; end
  class ConnectionError < StandardError; end
  class ProtocolError < StandardError; end

  module Commands
    def ping(message = nil) = _str(message.nil? ? call("PING") : call("PING", message))
    def echo(message) = _str(call("ECHO", message))
    def select(db) = _str(call("SELECT", db))
    def flushdb = _str(call("FLUSHDB"))
    def flushall = _str(call("FLUSHALL"))
    def dbsize = _int(call("DBSIZE"))

    def del(*keys) = _int(call("DEL", *keys))
    def exists(*keys) = _int(call("EXISTS", *keys))
    def exists?(*keys) = _positive(call("EXISTS", *keys))
    def expire(key, seconds) = _bool(call("EXPIRE", key, seconds))
    def ttl(key) = _int(call("TTL", key))
    def keys(pattern = "*") = _arr(call("KEYS", pattern))
    def type(key) = _str(call("TYPE", key))

    def get(key) = _str(call("GET", key))

    def set(key, value, ex: nil, px: nil, nx: false, xx: false)
      args = ["SET", key, value]
      args.push("EX", ex) if ex
      args.push("PX", px) if px
      args.push("NX") if nx
      args.push("XX") if xx
      (nx || xx) ? _okbool(call(*args)) : _str(call(*args))
    end

    def setnx(key, value) = _bool(call("SETNX", key, value))
    def mget(*keys) = _arr(call("MGET", *keys))
    def mset(*pairs) = _str(call("MSET", *pairs))
    def incr(key) = _int(call("INCR", key))
    def decr(key) = _int(call("DECR", key))
    def incrby(key, n) = _int(call("INCRBY", key, n))
    def decrby(key, n) = _int(call("DECRBY", key, n))
    def append(key, value) = _int(call("APPEND", key, value))
    def strlen(key) = _int(call("STRLEN", key))

    def hset(key, *pairs) = _int(call("HSET", key, *pairs.flat_map { |x| x.is_a?(Hash) ? x.to_a.flatten(1) : [x] }))
    def hget(key, field) = _str(call("HGET", key, field))
    def hmget(key, *fields) = _arr(call("HMGET", key, *fields))
    def hgetall(key) = _hash(call("HGETALL", key))
    def hdel(key, *fields) = _int(call("HDEL", key, *fields))
    def hexists(key, field) = _bool(call("HEXISTS", key, field))
    def hkeys(key) = _arr(call("HKEYS", key))
    def hvals(key) = _arr(call("HVALS", key))
    def hlen(key) = _int(call("HLEN", key))

    def lpush(key, *values) = _int(call("LPUSH", key, *values))
    def rpush(key, *values) = _int(call("RPUSH", key, *values))
    def lpop(key) = _str(call("LPOP", key))
    def rpop(key) = _str(call("RPOP", key))
    def lrange(key, start, stop) = _arr(call("LRANGE", key, start, stop))
    def llen(key) = _int(call("LLEN", key))
    def lindex(key, index) = _str(call("LINDEX", key, index))

    def sadd(key, *members) = _int(call("SADD", key, *members))
    def sadd?(key, member) = _bool(call("SADD", key, member))
    def srem(key, *members) = _int(call("SREM", key, *members))
    def srem?(key, member) = _bool(call("SREM", key, member))
    def smembers(key) = _arr(call("SMEMBERS", key))
    def sismember(key, member) = _bool(call("SISMEMBER", key, member))
    def scard(key) = _int(call("SCARD", key))
  end

  class PipelinedConnection
    include Commands
    attr_reader :commands, :tags

    def initialize
      @commands = []
      @tags = []
    end

    def call(*args)
      @commands << args
      nil
    end

    def _tag(t)
      @tags << t
      nil
    end

    def _str(v) = _tag(:str)
    def _int(v) = _tag(:int)
    def _bool(v) = _tag(:bool)
    def _okbool(v) = _tag(:okbool)
    def _positive(v) = _tag(:positive)
    def _arr(v) = _tag(:arr)
    def _hash(v) = _tag(:hash)

    def self.pairs_to_hash(items) = items.each_slice(2).to_h

    def shape(replies)
      replies.zip(@tags).map do |v, tag|
        case tag
        when :bool then v == 1
        when :okbool then v == "OK"
        when :positive then v.is_a?(Integer) && v > 0
        when :hash then v.is_a?(Array) ? PipelinedConnection.pairs_to_hash(v) : v
        else v
        end
      end
    end
  end

  include Commands
  attr_reader :host, :port, :db, :timeout

  # Redis.new(host: , port: , db: , timeout:) as the gem, or positional (host, port, db, timeout) as Sake's new
  def initialize(host_pos = nil, port_pos = nil, db_pos = nil, timeout_pos = nil, host: nil, port: nil, db: nil, timeout: nil)
    @host = host || host_pos || "127.0.0.1"
    @port = port || port_pos || 6379
    @db = db || db_pos || 0
    @timeout = timeout || timeout_pos || 5.0
    @sock = nil
  end

  def id = "redis://#{host}:#{port}/#{db}"
  def inspect = "#<Redis client for #{id}>"
  def to_s = inspect
  def connected? = !@sock.nil?

  def close
    @sock&.close
    @sock = nil
    nil
  end

  alias disconnect! close

  def connection
    return @sock if @sock
    begin
      s = Socket.tcp(host, port, connect_timeout: timeout)
    rescue SystemCallError, SocketError => e
      raise CannotConnectError, "Error connecting to Redis on #{host}:#{port} (#{e.message})"
    end
    @sock = s
    if db != 0
      s.write(_command(["SELECT", db]))
      _read_reply(s)
    end
    s
  end

  def call(*args)
    s = connection
    s.write(_command(args))
    _read_reply(s)
  end

  def _command(args)
    flat = args.flatten
    flat.map { |a| s = a.to_s; "$#{s.bytesize}\r\n#{s}\r\n" }.unshift("*#{flat.size}\r\n").join
  end

  def _read_line(s)
    line = s.gets
    if line.nil?
      close
      raise ConnectionError, "Connection lost (ECONNRESET)"
    end
    line.chomp
  end

  def _read_reply(s)
    line = _read_line(s)
    kind = line[0]
    rest = line[1..] || ""
    case kind
    when "+" then rest
    when "-" then raise CommandError, rest
    when ":" then rest.to_i
    when "$"
      n = rest.to_i
      n < 0 ? nil : s.read(n + 2).byteslice(0, n)
    when "*"
      n = rest.to_i
      n < 0 ? nil : Array.new(n) { _read_reply(s) }
    else
      raise ProtocolError, "Got '#{kind}' as initial reply byte"
    end
  end

  def _str(v)
    raise TypeError, "expected a String reply, got #{v.class}" unless v.nil? || v.is_a?(String)
    v
  end

  def _int(v)
    raise TypeError, "expected an Integer reply, got #{v.class}" unless v.is_a?(Integer)
    v
  end

  def _bool(v) = v == 1
  def _okbool(v) = v == "OK"
  def _positive(v) = v.is_a?(Integer) && v > 0

  def _arr(v)
    raise TypeError, "expected an Array reply, got #{v.class}" unless v.is_a?(Array)
    v
  end

  def _hash(v) = PipelinedConnection.pairs_to_hash(_arr(v))

  def pipelined
    pipe = PipelinedConnection.new
    yield pipe
    return [] if pipe.commands.empty?
    s = connection
    s.write(pipe.commands.map { |c| _command(c) }.join)
    pipe.shape(pipe.commands.map { _read_reply(s) })
  end

  def multi
    pipe = PipelinedConnection.new
    yield pipe
    s = connection
    s.write(_command(["MULTI"]) + pipe.commands.map { |c| _command(c) }.join + _command(["EXEC"]))
    _read_reply(s)
    pipe.commands.each { _read_reply(s) }
    pipe.shape(_read_reply(s))
  end
end
