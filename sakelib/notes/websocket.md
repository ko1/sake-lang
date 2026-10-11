# websocket (WebSocket::Handshake, WebSocket::Frame)

`require "websocket"` → `sakelib/websocket.sake`. Port of the websocket gem 1.2.11 for the protocol versions in
use: RFC 6455 (13) and the hybi drafts 04-17 for handshakes, 03-13 for frames.
Test: `test/sakelib/websocket.{sake,rb}` (identical output): client and server handshakes fed to each other,
the RFC 6455 1.3 key/accept example, a request in two pieces, subprotocols, wss, extra headers, the
Sec-WebSocket-Origin of drafts before 11, every handshake error, from_rack; outgoing frames of each type, close
codes, the 1/3/9-byte lengths, drafts 03/04/05/07 opcodes, masking (client → server), byte-by-byte input, two
frames in one buffer, fragmented messages, a 70000-byte frame, every frame error, max_frame_size, should_raise.
The random parts (the client key, the masking key) are hidden or checked by decoding on the other side.

## API

| Ruby | Sake | |
|---|---|---|
| `Handshake::Client.new(url: ..., origin:, headers:, protocols:, version:, host:, port:, path:, query:, secure:)` | `WebSocket::Handshake::Client.new(url: ..., ...)` | same (keywords are fields); `uri:` (alias of url) missing |
| `hs.to_s` / `hs << data` / `valid?` / `finished?` / `error` / `state` / `leftovers` / `should_respond?` | `WebSocket::Handshake::Client.to_s(hs)` / `hs << data` / … | same |
| `hs.host` / `port` / `path` / `query` / `secure` / `version` / `headers` / `protocols` / `origin` / `uri` / `default_port` / `default_port?` | `Client.host(hs)` / … | same |
| `Handshake::Server.new(secure:, protocols:)`, `<<`, `to_s`, `valid?`, `host`, `port`, `uri`, … | `WebSocket::Handshake::Server...` | same |
| `server.from_rack(env)` | `Server.from_rack(hs, env)` | same for an env of Strings (draft 76's rack.input body is not read) |
| `server.from_hash(headers:, path:, query:, body:)` | — | missing (a Hash of mixed values; from_rack covers it) |
| `Frame::Outgoing::Client/Server.new(version:, data:, type:, code:)` | `WebSocket::Frame::Outgoing::Server.new(version: 13, data: "x", type: :text)` | same |
| `frame.to_s` (encode) / `supported?` / `require_sending?` / `support_type?` / `error` / `error?` | `Outgoing::Server.to_s(f)` / … | same, but `to_s` gives "" where Ruby gives nil on an error |
| `Frame::Incoming::Client/Server.new(version:)`, `frame << bytes`, `frame.next` | `Incoming::Client.new(version: 13)`, `f << s`, `Incoming::Client.next(f)` | same |
| decoded `frame.type` / `data` / `code` / `decoded?` / `version` / `to_s` | `Incoming::Client.type(fr)` / … | same |
| `WebSocket.max_frame_size` / `max_frame_size=` / `should_raise` / `should_raise=` | `WebSocket.max_frame_size` / `set_max_frame_size(n)` / `should_raise` / `set_should_raise(b)` | differs: setter names |
| `WebSocket::Error::Frame::TooLong` etc. (13 frame + 7 handshake errors) | same nested names | differs: message is the String "frame_too_long" (Ruby: the Symbol); no hierarchy |
| drafts 75/76 and hybi 00-02 (Client75, Client76, Client01, Server75, Server76, Handler75) | — | missing: `:unknown_protocol_version` |
| `inspect` (NiceInspect, with the object address) | `p(frame)` prints the fields | differs |

About 45 operations ported.

## How it is organised, and what differs

- **Handlers.** Ruby picks a handler object per version (`Handler07 < Handler05 < Handler04 < Handler03`, `Client11
  < Client04`, `Server04`) and the frame/handshake delegates to it. Here the version is just a field, and the few
  places the drafts differ (`fin`: 04+, `masking?`: 05+, the opcode table: 07+, close codes: 07+, `Origin` vs
  `Sec-WebSocket-Origin`: 11+) are conditions on it. Inheritance chains of one-method classes become one function each.
- **Four frame classes share code through mixins**: `Frame::Base` (Ruby's Base, Data and handlers, including
  `initialize`), `Frame::Incoming` and `Frame::Outgoing` (which are also the namespaces of their `Client` and
  `Server`). Ruby's `@frame.class.new(...)` for a decoded frame becomes a `make` function each class defines.
- **rescue_method.** Ruby wraps `new`, `<<`, `to_s`, `valid?`, `next` so a `WebSocket::Error` sets `error` (the
  message Symbol) and returns nil/''/false, or re-raises when `should_raise`. Each of those functions here ends with
  `rescue => e` + `fail_with`. Because Sake has no exception hierarchy, there is no way to say "any
  WebSocket::Error" short of listing the 20 classes (and level 1 rejects listing ones a body never raises), so the
  bare rescue also catches non-WebSocket errors that Ruby would let through.
- **Module attributes** (`WebSocket.should_raise`, `max_frame_size`) live in a `once` Hash (no globals).
- **URL parsing** uses one regexp instead of `URI.parse` (ws/wss scheme, host, port, path, query).
- **Masking keys and the client key** use `rand` (Ruby: `SecureRandom.random_bytes(4)` and `rand(255)`).
- Ruby's `Frame::Data < String` (a String with a masking key) is not a class: masking is a function over the
  payload and the 4-byte key.

## Built-ins Sake lacks

- Class values (`@frame.class.new`): written as a `make` function per class.
- An exception hierarchy (see rescue_method).
- `SecureRandom.random_bytes`: `sakelib/securerandom.sake` exists; I used `rand` to keep the dependency small.

## Friction

- `Client.new(type, data, version: @version, decoded: true)` → "field `version` is already given as argument 2"
  (the fields are ordered by the attr_reader lines: type, version, error, decoded, data, code) → all keywords.
- Each class's `def initialize(f) = init_frame(f)` (the defaults set in a mixin function) → every later use of
  `@data` reports "argument 1 may be nil" (the checker does not see fields set in a helper called from initialize)
  → define `initialize` in the mixin itself; it is copied into each class and the checker then sees it.
- `Array.join(key, ": ")` on a `["Upgrade", "websocket"]` pair → "Array.join: argument 1 must be Array, but is
  [String, String]" → `|k, v| "#{k}: #{v}"`.
- `private attr_reader data, leftovers` plus the mixin's public `def leftovers(h)` → in the test,
  "field `leftovers` of WebSocket::Handshake::Client is private" (the field's reader replaced the mixin function)
  → renamed the field `rest`. The opposite case is silent: `def port(h)` in the class replaces the
  `attr_reader port`, which is what I wanted (Ruby's `@port || default_port`), but nothing says it happened.
- The long names: `WebSocket::Frame::Incoming::Client.type(frame)` on every read. The test lines are 2-3x longer
  than Ruby's.

## Size

Ruby (the 25 files ported, without drafts 75/76 and 01): 1530 lines, 973 without comments/blank (about 300 of
them are the 20 error classes with `def message`). Sake: 667 lines, 545 without comments/blank.
