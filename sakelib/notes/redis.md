# redis

`sakelib/redis.sake`: a client for the redis gem's API (redis-rb 5; not installed, so the reference is
`test/sakelib/ref/redis.rb`, a plain-Ruby client with the gem's method names and reply conversions). RESP2 over
`Socket.connect`; 47 commands (connection, keys, strings, hashes, lists, sets), `call` for any command,
`pipelined` and `multi` over a `RedisPipeline`, `close` / `connected?` / `id`; 55 operations on Redis, 48 on
RedisPipeline. The test starts a RESP server in a thread (`TCPServer`, an in-memory Hash, 42 commands, MULTI/EXEC,
expiry) in Sake and the same server in Ruby; both print 136 identical lines.

## API

| Ruby (redis-rb 5) | Sake | |
|---|---|---|
| `Redis.new(host:, port:, db:, timeout:)` | `Redis.new(host:, port:, db:, timeout:)` or positional | same (`url:`, `path:`, `ssl:`, `password:`, `reconnect_attempts:` missing) |
| `redis.ping`, `ping(msg)`, `echo`, `select`, `flushdb`, `flushall`, `dbsize` | `Redis.ping(r)`, … | same |
| `del(*keys)`, `exists(*keys)` → Integer, `exists?` → bool, `expire` → bool, `ttl`, `keys(pat)`, `type` | same | same |
| `get`, `set(k, v, ex:, px:, nx:, xx:)` → `"OK"` / bool with nx or xx, `setnx`, `mget`, `mset`, `incr`, `decr`, `incrby`, `decrby`, `append`, `strlen` | same | same (`set`'s `exat:`, `pxat:`, `keepttl:`, `get:` missing) |
| `hset(k, f, v, …)` / `hset(k, hash)` → Integer, `hget`, `hmget`, `hgetall` → Hash, `hdel`, `hexists`, `hkeys`, `hvals`, `hlen` | same | same (`hmset`, `hincrby`, `hsetnx`, `hscan` missing) |
| `lpush`, `rpush`, `lpop`, `rpop`, `lrange`, `llen`, `lindex` | same | same (`blpop`, `lrem`, `lset`, `ltrim`, `linsert` missing) |
| `sadd` → Integer, `sadd?` → bool, `srem`, `srem?`, `smembers`, `sismember` → bool, `scard` | same | same (`sunion`/`sinter`/`sdiff`, `spop`, `sscan` missing) |
| `redis.call("GET", "k")` → the raw reply | `Redis.call(r, "GET", "k")` | same (String, Integer, nil, Array; a Symbol or nested Array argument spread as the gem's) |
| `redis.pipelined { \|pipe\| pipe.set(…); pipe.get(…) }` → replies | `Redis.pipelined(r) { \|pipe\| RedisPipeline.set(pipe, …) }` | differs: `pipe.get` gives a Future in Ruby, nil here; the replies Array is shaped the same |
| `redis.multi { \|tx\| … }` → EXEC's replies | `Redis.multi(r) { \|tx\| … }` | same (`watch`/`unwatch`/`discard` missing) |
| `redis.close`, `disconnect!`, `connected?`, `id`, `inspect` | same | `inspect` lacks the gem's version string |
| `Redis::CommandError`, `CannotConnectError`, `ConnectionError`, `ProtocolError` | `RedisCommandError`, … | differs: flattened; `Redis::BaseError` hierarchy missing (no hierarchy) |
| sorted sets, pub/sub, scripting (`eval`), `scan_each` enumerators, RESP3 (`protocol: 3`), sentinel, cluster, `Redis.current`, `with_reconnect`, `Redis::Distributed` | — | missing: not in the budget (zsets), blocks as values (pub/sub `subscribe { \|on\| on.message { } }` stores blocks), RESP3's map/set/push types |

## できたこと / できなかったこと

- The gem's "Commands" modules became one mixin, `RedisCommands`, included by both `Redis` and `RedisPipeline`.
  Each command is one line: `def get(r, key) = _str(r, call(r, "GET", key))`. `call` and the seven reply shapers
  (`_str`, `_int`, `_bool`, `_okbool`, `_positive`, `_arr`, `_hash`) are the includer's own: in `Redis` they
  send and **assert the reply's shape** (`v => String | nil`, `v => Integer`, `v == 1`, pairs → Hash); in
  `RedisPipeline`, `call` queues the command and the shaper pushes a tag, applied to the replies after the
  round trip. This gives the gem's conversions (`exists?` → true/false, `hgetall` → Hash) in both modes and
  replaces the gem's Futures with nil + a shaped Array, which is what `pipelined` returns anyway.
- RESP2 reading is the gem's: first byte picks `+ - : $ *`, bulk replies read exactly `n + 2` bytes in a loop
  (`Socket.read` may stop short), an error reply raises `RedisCommandError` with the server's text, EOF raises
  `RedisConnectionError` and closes. Connecting is lazy (the gem's too), `SELECT db` on connect, `Socket.connect`'s
  `IOError` becomes `RedisCannotConnectError` with the gem's `Error connecting to Redis on host:port (...)`.
- Not done, Sake rules: pub/sub (`subscribe` keeps callbacks per channel: blocks are not values); the Future
  object of a pipelined call (a value whose `value` method is read later: a Struct could hold it, but its
  type would be the union of every command's reply; the tag approach keeps each command's shape instead);
  `Redis::BaseError` as a common rescue (no hierarchy: `rescue RedisCommandError, RedisConnectionError`).
  Not done for time: sorted sets, scan, blocking pops, more string/hash/list commands (the server side has to
  be written twice as well).

## 書き心地

- `def arity(cmd, args, n) = raise(...) if Array.size(args) < n` → Sake: `` `def` must be at the top level or
  directly in a class/module body `` and `undefined local variable or function `args`` at the `if`. Ruby would
  parse this the same way (the `if` modifies the `def`, and `args` is then unbound) but only fail at run time
  when `arity` turns out undefined; Sake refused before running and the two messages together pointed at the
  cause. Rewrote as a two-line def.
- Wrote the server's HGETALL reply as `Array.flatten(Hash.to_a(h))`, Ruby's `h.to_a.flatten` → `case/in: no
  in branch matches [nil | String, nil | String] [type]` at `resp_encode`'s `case`, with the chain `reached by
  the call at line 370 → 364 → 357 → 32`. Real mistake: `Hash.to_a` gives Tuples and `Array.flatten` leaves a
  Tuple whole (checked at run time too: `[["a", "1"]]`), so the encoder would have met a Tuple it has no
  branch for. The checker found it from the test program's call chain before any socket was opened. Fix:
  `Hash.each(h) { |f, v| Array.push(out, f, v) }` (or `Hash.flatten(h)`, which exists; found afterwards).
- The server's `string_at` did `v => String` for a key holding a Hash, so `Redis.get(r, "user")` made the server
  thread die with `NoMatchingPatternError`, silently ("a thread that is never joined ends silently when it
  fails"), and the client sat in `Socket.gets` until the 5 s timeout: `IOError: Socket.gets: Blocking operation
  timed out!`. The timeout made it a diagnosis instead of a hang, but a line on stderr when a thread dies
  (Ruby's `report_on_exception`) would have named the real line at once. Fix: `case v in nil | String then v
  else wrongtype end`, the real server's `WRONGTYPE` reply.
- `_read_reply` returns `String | Integer | nil | Array`; the typed wrappers narrow with `v => String | nil` etc.
  Writing `String.upcase(Redis.call(r, "GET", "k"))` is rightly refused under `--strict` (`argument 1 must be
  String, but can be Integer | nil | Array[...]`, verified) while `String.upcase(Redis.get(r, "k") || "")` passes: the API's promise ("get gives a String or nil") is now
  checked where the gem documents it in a comment.
- `kind = String.[](line, 0) || ""` and `rest = String.[](line, 1, String.length(line) - 1) || ""`: slices are
  `String | nil` and `--strict` wants the `|| ""`; the gem's `line[0]`/`line[1..]` carry the same nil unchecked.
- `Redis.new(host: "127.0.0.1", port: port)` is the gem's call unchanged because `new` takes fields by
  keyword; `private attr_accessor sock` hides the socket and `initialize` fills the defaults
  (`@port = 6379 if @port == nil`, then `@port => Integer`), so `Redis.new(host: "x", port: "6379")` is
  `` `=> Integer`: the value is String, which does not match [type] `` at the initialize line, with
  `reached by the call at line 3` (verified).
- The mixin: `include RedisCommands` in two types, with `call` resolved in each includer, is exactly the gem's
  structure (`Redis::Commands` included in `Redis` and `Redis::PipelinedConnection`), and the typer analyzes
  the one body twice: `Redis.get` is `String | nil`, `RedisPipeline.get` is nil. A missing shaper in one
  includer would be a static error at the `include` line, which is how the design was checked while writing it.
- `Array.flatten(args)` in `_command` spreads a nested Array argument (`del(["a", "b"])`) as the gem does;
  `"#{a}"` for every argument (Integer, Symbol, Float) is the gem's `to_s`. `Array.push(args, "EX", ex) if ex != nil`
  builds SET's options as Ruby's `args << "EX" << ex`.
- Server side (test): `Db` with `store` and `expires` Hashes, `fetch`/`put`/`alive?`, each command a `case`
  branch with `arity(cmd, args, n)` and `to_int(s)` raising `RespError`, rescued in `run` and encoded as `-ERR`.
  `resp_encode` dispatches on the reply's type (`nil`, Integer, Symbol for simple strings, String for bulk,
  Array, RespError) with `case/in`; the Ruby twin is the same code with `when`. Both test files are 580 lines.

## Built-ins requested

- A stderr report when a Thread ends with an exception (Ruby's `Thread.report_on_exception`, default true):
  a dead server thread is otherwise found only through the client's timeout.
- `Socket.read` of exactly n bytes (Ruby's `read(n)` blocks until n bytes or EOF): every protocol client
  (net_http has the same `_read_n` loop) rewrites the loop; or document that `Socket.read` is `readpartial`.
- `Array.flatten` spreading Tuples, or a hint at `Array.flatten(Hash.to_a(h))` pointing to `Hash.flatten`:
  Ruby's `h.to_a.flatten` is a reflex.
- `Socket.connect(host, port, timeout)` with a distinct error for "connection refused" vs "timed out"
  (the gem distinguishes `CannotConnectError` from `TimeoutError`); today both are `IOError` with Ruby's message.
