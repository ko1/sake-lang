# net_smtp (Net::SMTP)

`require "net_smtp"` → `sakelib/net_smtp.sake`. Port of the net-smtp gem 0.5.1 (and the parts of net-protocol's
InternetMessageIO it uses: CRLF lines, dot-stuffing, the final ".").
Test: `test/sakelib/net_smtp.{sake,rb}` (identical output). Both programs contain the same tiny SMTP server (a
TCPServer on an ephemeral port, one Thread per connection, whose value is the transcript it heard) and print the
client's results and then the server's transcript: a session with a block, EHLO capabilities, a message to two
recipients with a leading dot and mixed newlines, HELO fallback when EHLO is refused, AUTH PLAIN / LOGIN / CRAM-MD5
(the server logs the HMAC) / XOAUTH2, bad credentials, 550 / 450 / 553 replies (QUIT is then skipped), new + start
without a block, mailfrom/rcptto/rset one by one, a CR/LF injection attempt, open_message_stream, SMTPUTF8 for a
non-ASCII recipient, finish twice, a closed session, argument errors, a refused connection, Response and Address.

## API

| Ruby | Sake | |
|---|---|---|
| `Net::SMTP.start(address, port, helo, user, secret, authtype) { \|smtp\| }` | `Net::SMTP.start(address, port, helo, user, secret, authtype) { \|smtp\| }` | same (positional; Ruby's keywords helo:, user:, … missing) |
| `Net::SMTP.new(address, port = 25)` | `Net::SMTP.new(address, port)` | same; `tls:`/`starttls:` are fields (`Net::SMTP.new(a, p, tls: true)`) |
| `smtp.start(helo, user, secret, authtype) [{ }]` | `Net::SMTP.start_session(smtp, helo, user, secret, authtype) [{ }]` | differs: name (one name is one function; `start` is the class method) |
| `smtp.finish` / `started?` | `Net::SMTP.finish(smtp)` / `started?` | same |
| `smtp.send_message(msg, from, *to)` / `send_mail` | `Net::SMTP.send_message(smtp, msg, from, *to)` / `send_mail` | same, but `to` must be Strings (Ruby flattens Arrays: pass `*list`) |
| `smtp.open_message_stream(from, *to) { \|f\| f.puts … }` | `Net::SMTP.open_message_stream(smtp, from, *to) { \|f\| Net::SMTP::MessageStream.puts(f, …) }` | same (`f << s` works) |
| `smtp.mailfrom(addr)` / `rcptto(addr)` / `rcptto_list` / `data(msg)` / `rset` / `quit` / `helo` / `ehlo` / `starttls` | `Net::SMTP.mailfrom(smtp, addr)` / … | same; `data` takes the message (the block form is open_message_stream) |
| `smtp.authenticate(user, secret, authtype)` | `Net::SMTP.authenticate(smtp, user, secret, authtype)` | same for :plain, :login, :cram_md5, :xoauth2 |
| `smtp.get_response(line)` | `Net::SMTP.get_response(smtp, line)` | same |
| `capabilities` / `capable?(k)` / `capable_*_auth?` / `capable_auth_types` / `capable_starttls?` / `auth_capable?` | `Net::SMTP.capabilities(smtp)` / … | same |
| `esmtp` / `esmtp?` / `esmtp=` / `open_timeout(=)` / `read_timeout(=)` | `Net::SMTP.esmtp(smtp)` / `set_esmtp(smtp, b)` / … | same, setters named `set_x` |
| `tls?` / `ssl?` / `enable_tls` / `disable_tls` / `starttls?` / `starttls_always?` / `starttls_auto?` / `enable_starttls(_auto)` / `disable_starttls` | same names | same (no SSLContext argument) |
| `debug_output = io` / `set_debug_output(io)` | `Net::SMTP.set_debug_output(smtp, io)` | differs: an IO only; lines are `<- "…"` / `-> "…"`, not net-protocol's exact format |
| `Net::SMTP.default_port` / `default_submission_port` / `default_tls_port` / `default_ssl_port` | same | same |
| `smtp.inspect` | `Net::SMTP.inspect(smtp)` | same |
| `Net::SMTP::Response.parse(s)`, `status`, `string`, `success?`, `continue?`, `message`, `capabilities`, `cram_md5_challenge`, `status_type_char` | same | same |
| `res.exception_class` | — | missing (no class values; raising is internal: `raise_for`) |
| `Net::SMTP::Address.new(addr, *params)` / `address` / `parameters` / `to_s` | `Net::SMTP::Address.new(addr, String[params])` | differs: params as one Array; keyword params (`size: 100`) missing |
| `SMTPAuthenticationError`, `SMTPServerBusy`, `SMTPSyntaxError`, `SMTPFatalError`, `SMTPUnknownError`, `SMTPUnsupportedCommand` (+ `#response`) | same names, `Net::SMTPFatalError.response(e)` | differs: no hierarchy (`rescue Net::SMTPError` / `Net::ProtocolError` is impossible) |
| `tls: true` (SMTPS, port 465) | `Net::SMTP.new(a, 465, tls: true)` | via `Socket.connect_ssl` (untested: no TLS server in the test) |
| STARTTLS | — | missing: raises SMTPUnsupportedCommand when the session would need it |
| `ssl_context_params`, `tls_verify`, `tls_hostname`, custom Authenticator classes (`auth_type :foo`) | — | missing |
| `Net::SMTPSession` (alias) | — | missing (no class aliases) |

About 60 operations ported.

## What differs, and why

- **One name, one function.** Ruby has both `Net::SMTP.start` (class) and `smtp.start` (instance); the instance
  form is `start_session`.
- **No keyword arguments** at call sites (this week's convention): start takes Ruby's positional form, which the
  gem also accepts.
- **Raising by reply code.** `raise res.exception_class.new(res)` needs a class as a value; `raise_for(res)` picks
  the class with `if`s. The exceptions carry the Response as a field after the message.
- **SMTPError as a group.** `do_helo` rescues "any SMTPError" to fall back to HELO; here it lists the five
  classes. `critical` (which marks the session broken on any exception) uses a bare rescue, as Ruby's `rescue Exception`.
- **STARTTLS** needs an existing Socket upgraded to TLS, which Sake's Socket cannot do. Ruby without openssl
  also fails there; here the error is explicit (`SMTPUnsupportedCommand`) instead of sending in the clear.
- **Timeouts** go to `Socket.connect(host, port, open_timeout)` and `Socket.set_timeout(read_timeout)`; Ruby's
  Net::OpenTimeout / Net::ReadTimeout classes are not reproduced (whatever Sake's Socket raises comes through).
- **open_message_stream** collects what the block writes and sends it as one message; Ruby streams it line by
  line. The bytes on the wire are the same.
- A refused connection: Ruby raises Errno::ECONNREFUSED (a SystemCallError); Sake's Socket raises IOError, so the
  test's rescue lines differ (`SystemCallError, IOError` vs `IOError`).

## Built-ins Sake lacks (requests)

- `Socket.start_tls(sock, hostname)` (upgrade a connected Socket): for STARTTLS here, and for IMAP/POP3/FTP.
- Class values or an exception hierarchy (`rescue Net::SMTPError`).

## Friction

- Ruby's `start` twice (class and instance) → "one name is one function" → `start_session` for the instance.
- `res.exception_class.new(res)` → no class values → `raise_for(res)` with five `raise ... if String.start_with?`.
- `rescue SMTPError` (a mixin of exceptions) → no hierarchy → list the classes; level 1 would reject one that the
  body never raises, so the list has to be exactly the ones getok can raise.
- In the test, `Net::SMTPAuthenticationError.response(e)&.Net::SMTP::Response.status` (from habit) was
  accepted, although `&.` is listed as rejected; it runs as `.` (no nil short-circuit). Repro:
  `sakelib/notes/net_smtp_bug_safe_nav_chain.sake`. Removed the `&` (the field is never nil for that class, and
  the checker knows it).
- Threads and sockets in the test server worked unchanged from the Ruby version (`Thread.new { }`, `Thread.value`,
  `TCPServer.accept`, `Socket.gets/write`), which made the side-by-side test easy.

## Size

Ruby: `net/smtp.rb` + `net/smtp/*.rb` 1306 lines (618 without comments/blank; the gem's comments are its docs).
Sake: 511 lines (391 without comments/blank).
