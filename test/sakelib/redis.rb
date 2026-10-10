require_relative "ref/redis"
require "socket"
require "set"

# --- a tiny RESP2 server on an ephemeral port, in a thread: an in-memory Hash, the commands the test uses ---
class RespError < StandardError; end

Db = Struct.new(:store, :expires)       # key => String | Array (list) | Set | Hash; key => Time

def resp_read_command(c)
  line = c.gets
  return nil unless line
  n = line.chomp[1..].to_i
  args = []
  n.times do
    len_line = c.gets
    return nil unless len_line
    len = len_line.chomp[1..].to_i
    data = c.read(len + 2) || ""
    args << (data.byteslice(0, len) || "")
  end
  args
end

def resp_encode(v)
  case v
  when nil then "$-1\r\n"
  when Integer then ":#{v}\r\n"
  when Symbol then "+#{v}\r\n"
  when String then "$#{v.bytesize}\r\n#{v}\r\n"
  when Array then "*#{v.size}\r\n" + v.map { |x| resp_encode(x) }.join
  when RespError then "-#{v.message}\r\n"
  end
end

def alive?(db, key)
  exp = db.expires[key]
  if exp && exp <= Time.now
    db.store.delete(key)
    db.expires.delete(key)
  end
  db.store.key?(key)
end

def fetch(db, key) = alive?(db, key) ? db.store[key] : nil

def put(db, key, v)
  db.store[key] = v
  db.expires.delete(key)
  v
end

def wrongtype = raise(RespError, "WRONGTYPE Operation against a key holding the wrong kind of value")

def string_at(db, key)
  v = fetch(db, key)
  case v
  when nil, String then v
  else wrongtype
  end
end

def int_at(db, key)
  s = string_at(db, key)
  return 0 if s.nil?
  raise RespError, "ERR value is not an integer or out of range" unless s.match?(/\A-?\d+\z/)
  s.to_i
end

def list_at(db, key, create)
  v = fetch(db, key)
  if v.nil?
    l = []
    put(db, key, l) if create
    return l
  end
  case v
  when Array then v
  else wrongtype
  end
end

def hash_at(db, key, create)
  v = fetch(db, key)
  if v.nil?
    h = {}
    put(db, key, h) if create
    return h
  end
  case v
  when Hash then v
  else wrongtype
  end
end

def set_at(db, key, create)
  v = fetch(db, key)
  if v.nil?
    s = Set[]
    put(db, key, s) if create
    return s
  end
  case v
  when Set then v
  else wrongtype
  end
end

def arity(cmd, args, n)
  raise RespError, "ERR wrong number of arguments for '#{cmd.downcase}' command" if args.size < n
end

def to_int(s)
  raise RespError, "ERR value is not an integer or out of range" unless s.match?(/\A-?\d+\z/)
  s.to_i
end

def glob_to_re(pat) = Regexp.new("\\A" + Regexp.escape(pat).gsub("\\*", ".*").gsub("\\?", ".") + "\\z")

def lrange_of(l, start, stop)
  n = l.size
  s = start < 0 ? n + start : start
  e = stop < 0 ? n + stop : stop
  s = 0 if s < 0
  e = n - 1 if e >= n
  return [] if s > e || s >= n
  l[s, e - s + 1] || []
end

def execute(db, cmd, args)
  case cmd.upcase
  when "PING" then args.empty? ? :PONG : args.fetch(0)
  when "ECHO"
    arity(cmd, args, 1)
    args.fetch(0)
  when "SELECT" then :OK
  when "FLUSHDB", "FLUSHALL"
    db.store.clear
    db.expires.clear
    :OK
  when "DBSIZE" then db.store.keys.count { |k| alive?(db, k) }
  when "DEL"
    arity(cmd, args, 1)
    args.count { |k| alive?(db, k) && !db.store.delete(k).nil? }
  when "EXISTS"
    arity(cmd, args, 1)
    args.count { |k| alive?(db, k) }
  when "EXPIRE"
    arity(cmd, args, 2)
    key = args.fetch(0)
    secs = to_int(args.fetch(1))
    if !alive?(db, key)
      0
    elsif secs <= 0
      db.store.delete(key)
      1
    else
      db.expires[key] = Time.now + secs
      1
    end
  when "TTL"
    arity(cmd, args, 1)
    key = args.fetch(0)
    exp = db.expires[key]
    if !alive?(db, key)
      -2
    elsif exp.nil?
      -1
    else
      (exp - Time.now).ceil
    end
  when "KEYS"
    arity(cmd, args, 1)
    re = glob_to_re(args.fetch(0))
    db.store.keys.select { |k| alive?(db, k) && k.match?(re) }
  when "TYPE"
    arity(cmd, args, 1)
    case fetch(db, args.fetch(0))
    when nil then :none
    when String then :string
    when Array then :list
    when Hash then :hash
    when Set then :set
    end
  when "GET"
    arity(cmd, args, 1)
    string_at(db, args.fetch(0))
  when "SET"
    arity(cmd, args, 2)
    key = args.fetch(0)
    value = args.fetch(1)
    opts = args.drop(2)
    ex = nil
    nx = false
    xx = false
    i = 0
    while i < opts.size
      o = opts.fetch(i).upcase
      case o
      when "EX"
        ex = to_int(opts.fetch(i + 1))
        i += 1
      when "PX"
        ex = Rational(to_int(opts.fetch(i + 1)), 1000)
        i += 1
      when "NX" then nx = true
      when "XX" then xx = true
      else raise RespError, "ERR syntax error"
      end
      i += 1
    end
    present = alive?(db, key)
    if (nx && present) || (xx && !present)
      nil
    else
      put(db, key, value)
      db.expires[key] = Time.now + ex if ex
      :OK
    end
  when "SETNX"
    arity(cmd, args, 2)
    key = args.fetch(0)
    if alive?(db, key)
      0
    else
      put(db, key, args.fetch(1))
      1
    end
  when "MGET"
    arity(cmd, args, 1)
    args.map { |k| string_at(db, k) }
  when "MSET"
    arity(cmd, args, 2)
    args.each_slice(2) { |k, v| put(db, k, v) }
    :OK
  when "INCR", "DECR", "INCRBY", "DECRBY"
    arity(cmd, args, cmd.upcase.end_with?("BY") ? 2 : 1)
    key = args.fetch(0)
    by = cmd.upcase.end_with?("BY") ? to_int(args.fetch(1)) : 1
    by = -by if cmd.upcase.start_with?("DECR")
    n = int_at(db, key) + by
    db.store[key] = n.to_s
    n
  when "APPEND"
    arity(cmd, args, 2)
    key = args.fetch(0)
    s = (string_at(db, key) || "") + args.fetch(1)
    db.store[key] = s
    s.bytesize
  when "STRLEN"
    arity(cmd, args, 1)
    (string_at(db, args.fetch(0)) || "").bytesize
  when "HSET"
    arity(cmd, args, 3)
    h = hash_at(db, args.fetch(0), true)
    added = 0
    args.drop(1).each_slice(2) do |f, v|
      added += 1 unless h.key?(f)
      h[f] = v
    end
    added
  when "HGET"
    arity(cmd, args, 2)
    hash_at(db, args.fetch(0), false)[args.fetch(1)]
  when "HMGET"
    arity(cmd, args, 2)
    h = hash_at(db, args.fetch(0), false)
    args.drop(1).map { |f| h[f] }
  when "HGETALL"
    arity(cmd, args, 1)
    out = []
    hash_at(db, args.fetch(0), false).each { |f, v| out.push(f, v) }
    out
  when "HDEL"
    arity(cmd, args, 2)
    key = args.fetch(0)
    h = hash_at(db, key, false)
    n = args.drop(1).count { |f| !h.delete(f).nil? }
    db.store.delete(key) if h.empty?
    n
  when "HEXISTS"
    arity(cmd, args, 2)
    hash_at(db, args.fetch(0), false).key?(args.fetch(1)) ? 1 : 0
  when "HKEYS"
    arity(cmd, args, 1)
    hash_at(db, args.fetch(0), false).keys
  when "HVALS"
    arity(cmd, args, 1)
    hash_at(db, args.fetch(0), false).values
  when "HLEN"
    arity(cmd, args, 1)
    hash_at(db, args.fetch(0), false).size
  when "LPUSH", "RPUSH"
    arity(cmd, args, 2)
    l = list_at(db, args.fetch(0), true)
    args.drop(1).each { |v| cmd.upcase == "LPUSH" ? l.unshift(v) : l.push(v) }
    l.size
  when "LPOP", "RPOP"
    arity(cmd, args, 1)
    key = args.fetch(0)
    l = list_at(db, key, false)
    v = cmd.upcase == "LPOP" ? l.shift : l.pop
    db.store.delete(key) if l.empty?
    v
  when "LRANGE"
    arity(cmd, args, 3)
    lrange_of(list_at(db, args.fetch(0), false), to_int(args.fetch(1)), to_int(args.fetch(2)))
  when "LLEN"
    arity(cmd, args, 1)
    list_at(db, args.fetch(0), false).size
  when "LINDEX"
    arity(cmd, args, 2)
    list_at(db, args.fetch(0), false)[to_int(args.fetch(1))]
  when "SADD"
    arity(cmd, args, 2)
    s = set_at(db, args.fetch(0), true)
    args.drop(1).count { |m| !s.add?(m).nil? }
  when "SREM"
    arity(cmd, args, 2)
    key = args.fetch(0)
    s = set_at(db, key, false)
    n = args.drop(1).count { |m| !s.delete?(m).nil? }
    db.store.delete(key) if s.empty?
    n
  when "SMEMBERS"
    arity(cmd, args, 1)
    set_at(db, args.fetch(0), false).to_a.sort
  when "SISMEMBER"
    arity(cmd, args, 2)
    set_at(db, args.fetch(0), false).include?(args.fetch(1)) ? 1 : 0
  when "SCARD"
    arity(cmd, args, 1)
    set_at(db, args.fetch(0), false).size
  else
    raise RespError, "ERR unknown command '#{cmd}', with args beginning with: #{args.map { |a| "'#{a}' " }.join}"
  end
end

def run(db, cmd, args)
  execute(db, cmd, args)
rescue RespError => e
  e
end

# One connection: commands until EOF; MULTI queues until EXEC.
def serve_client(db, c)
  tx = nil
  cmd = resp_read_command(c)
  while cmd
    name = cmd.fetch(0, "").upcase
    args = cmd.drop(1)
    reply = if name == "MULTI"
      tx = []
      :OK
    elsif name == "EXEC"
      queued = tx || []
      tx = nil
      queued.map { |q| run(db, q.fetch(0), q.drop(1)) }
    elsif tx
      tx.push(cmd)
      :QUEUED
    else
      run(db, name, args)
    end
    c.write(resp_encode(reply))
    cmd = resp_read_command(c)
  end
  c.close
end

def serve(srv, db)
  loop { serve_client(db, srv.accept) }
end

srv = TCPServer.new("127.0.0.1", 0)
port = srv.addr[1]
db = Db.new({}, {})
server = Thread.new { serve(srv, db) }
server.report_on_exception = false

# --- the client ---
puts("-- connect")
r = Redis.new(host: "127.0.0.1", port: port)
p([r.host, r.port == port, r.db, r.connected?])
p(r.id == "redis://127.0.0.1:#{port}/0")
p(r.ping)
p(r.ping("hello"))
p(r.echo("echo"))
p(r.connected?)
p(r.flushdb)
p(r.dbsize)

puts("-- strings")
p(r.set("name", "sake"))
p(r.get("name"))
p(r.get("missing"))
p(r.set("n", 10))
p(r.incr("n"))
p(r.incrby("n", 5))
p(r.decr("n"))
p(r.decrby("n", 3))
p(r.get("n"))
p(r.incr("fresh"))
p(r.append("name", "-lang"))
p(r.strlen("name"))
p(r.get("name"))
p(r.set("name", "x", nx: true))
p(r.set("new", "x", nx: true))
p(r.set("nope", "x", xx: true))
p(r.set("new", "y", xx: true))
p(r.setnx("new", "z"))
p(r.setnx("new2", "z"))
p(r.mset("a", 1, "b", 2))
p(r.mget("a", "b", "c"))
p(r.mget(["a", "name"]))
p(r.exists("a", "b", "c"))
p(r.exists?("a"))
p(r.exists?("c"))
p(r.del("a", "b", "c"))
p(r.exists("a"))
p(r.type("name"))
p(r.type("missing"))
p(r.keys.sort)
p(r.keys("n*").sort)
p(r.keys("?"))
begin
  r.incr("name")
rescue Redis::CommandError => e
  puts("Redis::CommandError: #{e.message}")
end

puts("-- expiry")
p(r.set("temp", "v"))
p(r.ttl("temp"))
p(r.expire("temp", 100))
p(r.ttl("temp"))
p(r.expire("missing", 100))
p(r.ttl("missing"))
p(r.set("short", "v", ex: 100))
p(r.ttl("short"))
p(r.set("ms", "v", px: 50000))
p(r.ttl("ms"))
p(r.expire("ms", 0))
p(r.exists("ms"))
p(r.set("gone", "v", px: 1))
sleep(0.01)
p([r.get("gone"), r.exists?("gone"), r.ttl("gone")])

puts("-- hashes")
p(r.hset("user", "name", "ko1", "lang", "ruby"))
p(r.hset("user", {"lang" => "sake", "age" => 1}))
p(r.hget("user", "name"))
p(r.hget("user", "nope"))
p(r.hgetall("user"))
p(r.hgetall("nohash"))
p(r.hmget("user", "name", "nope", "age"))
p(r.hexists("user", "age"))
p(r.hexists("user", "nope"))
p(r.hkeys("user"))
p(r.hvals("user"))
p(r.hlen("user"))
p(r.hdel("user", "age", "nope"))
p(r.hgetall("user"))
p(r.type("user"))
begin
  r.get("user")
rescue Redis::CommandError => e
  puts("Redis::CommandError: #{e.message}")
end

puts("-- lists")
p(r.rpush("q", "a"))
p(r.rpush("q", "b", "c"))
p(r.lpush("q", "z"))
p(r.llen("q"))
p(r.lrange("q", 0, -1))
p(r.lrange("q", 1, 2))
p(r.lrange("q", -2, -1))
p(r.lrange("q", 5, 10))
p(r.lindex("q", 0))
p(r.lindex("q", -1))
p(r.lindex("q", 9))
p(r.lpop("q"))
p(r.rpop("q"))
p(r.lrange("q", 0, -1))
p(r.lpop("empty"))
p(r.llen("empty"))
p(r.type("q"))
begin
  r.lpush("name", "x")
rescue Redis::CommandError => e
  puts("Redis::CommandError: #{e.message}")
end

puts("-- sets")
p(r.sadd("tags", "a", "b"))
p(r.sadd("tags", "b", "c"))
p(r.sadd?("tags", "d"))
p(r.sadd?("tags", "d"))
p(r.smembers("tags"))
p(r.sismember("tags", "a"))
p(r.sismember("tags", "zz"))
p(r.scard("tags"))
p(r.srem("tags", "a", "zz"))
p(r.srem?("tags", "b"))
p(r.srem?("tags", "b"))
p(r.smembers("tags"))
p(r.smembers("noset"))
p(r.type("tags"))

puts("-- call")
p(r.call("SET", "raw", "1"))
p(r.call("GET", "raw"))
p(r.call("INCR", "raw"))
p(r.call("GET", "nothing"))
p(r.call("MGET", "raw", "nothing"))
p(r.call(:ping))
p(r.call("DEL", ["raw", "name"]))
begin
  r.call("NOSUCH", "a", "b")
rescue Redis::CommandError => e
  puts("Redis::CommandError: #{e.message}")
end
begin
  r.call("GET")
rescue Redis::CommandError => e
  puts("Redis::CommandError: #{e.message}")
end

puts("-- pipelined, multi")
replies = r.pipelined do |pipe|
  p(pipe.set("p1", "one"))
  pipe.set("p2", 2)
  pipe.get("p1")
  pipe.incr("p2")
  pipe.exists?("p1")
  pipe.expire("p1", 100)
  pipe.hset("ph", "k", "v")
  pipe.hgetall("ph")
  pipe.mget("p1", "p2", "nope")
  pipe.set("p1", "x", nx: true)
  pipe.call("TYPE", "ph")
  pipe.get("nope")
end
p(replies)
p(r.pipelined { |pipe| })
p(r.multi { |tx| })
replies = r.multi do |tx|
  tx.incr("counter")
  tx.incr("counter")
  tx.get("counter")
  tx.sadd("s", "m")
  tx.smembers("s")
end
p(replies)
p(r.get("counter"))

puts("-- close, reconnect, errors")
p(r.close)
p(r.connected?)
p(r.get("counter"))
p(r.connected?)
r.disconnect!
r2 = Redis.new("127.0.0.1", port, 3)
p(r2.ping)
p(r2.id == "redis://127.0.0.1:#{port}/3")
r2.close
closed = TCPServer.new("127.0.0.1", 0)
closed_port = closed.addr[1]
closed.close
bad = Redis.new(host: "127.0.0.1", port: closed_port)
begin
  bad.get("x")
rescue Redis::CannotConnectError => e
  puts("Redis::CannotConnectError: #{e.message.start_with?("Error connecting to Redis on 127.0.0.1:")}")
end
p(bad.connected?)

srv.close
puts("end")
