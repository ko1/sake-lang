# open_uri (Ruby's open-uri, http:// only)

`require "open_uri"` → `sakelib/open_uri.sake` (requires `uri` and `net_http`). Test: the open-uri half of
`test/sakelib/net_http.{sake,rb}` (one server serves both; identical output).

Ruby's `URI.open(url)` is `OpenURI.open(url)` here: `URI` is the type of `sakelib/uri.sake`, and a type's
operations are defined in one library, so this file cannot add `open` to it. Ruby also has
`OpenURI.open_uri`, kept with that name. The result is an `OpenURIMeta` (Ruby: a StringIO extended with
`OpenURI::Meta`): the body with a read position plus `status`, `meta`, `content_type`, `charset`,
`base_uri`. Nested names flattened: `OpenURI::HTTPError` → `OpenURIHTTPError` (fields `message`, `io`),
`OpenURI::HTTPRedirect` → `OpenURIHTTPRedirect` (`io`, `uri`), `OpenURI::TooManyRedirects` →
`OpenURITooManyRedirects` (`io`).

## API

| Ruby | Sake | |
|---|---|---|
| `URI.open(url)` / `URI.open(url) { \|f\| }` | `OpenURI.open(url)` / with a block | differs: namespace (above); `url` is a String or a URI |
| `OpenURI.open_uri(url, options)` | `OpenURI.open_uri(url, options)` | same |
| `URI.open(url, "User-Agent" => "x")` (String keys: request headers) | `OpenURI.open(url, Hash["User-Agent" => "x"])` | same (an options Hash, no keywords) |
| `redirect: false` | `Hash[:redirect => false]` | same (raises `OpenURIHTTPRedirect`) |
| `max_redirects: n` | `Hash[:max_redirects => n]` | same (raises `OpenURITooManyRedirects`; default: unlimited, loops detected as Ruby's `"HTTP redirection loop: URL"` RuntimeError) |
| `http_basic_authentication: [user, pass]` | `Hash[:http_basic_authentication => ["u", "p"]]` | same (not sent after a redirect, as Ruby) |
| `proxy:`, `proxy_http_basic_authentication:`, `ssl_verify_mode:`, `ssl_ca_cert:`, `read_timeout:`, `open_timeout:`, `progress_proc:`, `content_length_proc:`, `ftp_active_mode:`, `request_specific_fields:` | — | missing (no proxies, TLS, timeouts, or blocks as values) |
| `https://`, `ftp://`, local file names | — | missing: `ArgumentError` for https (no TLS) and for anything not `http://host` |
| `f.read`, `f.read(n)` | `OpenURIMeta.read(f)`, `read(f, n)` | same (the rest / at most n bytes, nil at the end; `""` for `read(0)`) |
| `f.gets`, `readline`, `readlines`, `each_line { }`, `eof?`, `rewind`, `string`, `size`, `close`, `closed?` | same names | same (StringIO's subset; `pos` is a reader) |
| `f.status` | `OpenURIMeta.status(f)` | same (`["200", "OK"]`) |
| `f.base_uri` | `OpenURIMeta.base_uri(f)` | same (the final URI after redirects) |
| `f.meta`, `f.metas` | `OpenURIMeta.meta(f)`, `metas` | same (downcased names; `meta` joins repeated fields with ", ") |
| `f.content_type` | `OpenURIMeta.content_type(f)` | same (`"application/octet-stream"` without the field) |
| `f.charset` / `f.charset { default }` | `OpenURIMeta.charset(f)` | same without the block (`"utf-8"` for `text/*` without a charset, as Ruby ≥ 3.x; nil otherwise) |
| `f.content_encoding` | `OpenURIMeta.content_encoding(f)` | same (`identity` is removed by net_http, as Ruby's) |
| `f.last_modified` | `OpenURIMeta.last_modified(f)` | differs: the header String, not a Time (no `Time.httpdate`) |
| `e.io` on `HTTPError` (the body and status of the error response) | `OpenURIHTTPError.io(e)` | same |
| `p f` → `#<StringIO:0x...>` | `p(f)` → `#<OpenURIMeta 200 OK text/plain 14 bytes>` | differs (Ruby's shows an address; the test prints Sake's form from Ruby) |

24 operations ported (2 module functions, 22 on OpenURIMeta) and 3 exception types.

## How it works, and what differs

- `open_uri` loops: `NetHTTPGet` with the option headers → `NetHTTP.start { request }` → 2xx returns, 301/
  302/303/307/308 follow `Location` (relative ones merged with `URI.merge`, as Ruby), anything else raises
  `OpenURIHTTPError` with the response wrapped as the `io`. Visited URLs are kept in a Set for Ruby's loop
  detection.
- The body is `force_encoding`'d to the charset when the encoding name is known, else `ASCII-8BIT`, as
  Ruby's `meta_setup_encoding`; so `read` of a `text/html` body is UTF-8 and of an `octet-stream` body is
  binary, as in Ruby.
- `read` keeps a byte position; `gets` splits on `"\n"` with `String.byteindex`, so a multibyte body is
  cut on byte boundaries exactly as StringIO does. This port does not depend on `sakelib/stringio.sake`
  (written in parallel).

## Built-ins Sake lacks (requests)

See `net_http.md`: TLS, socket timeouts, inflate, `Time.httpdate`, `ENV`. In addition: nothing new for this
file; it is all Sake-level code over `net_http`.

## Friction

- Field order is `new`'s argument order. `attr_reader status` / `attr_accessor base_uri` / `private
  attr_reader fields` / `private attr_accessor body, pos` and `OpenURIMeta.new(body, status, fields, nil)`
  put the body in `status` and nil in `fields`; nothing complained statically (the `new` is untyped by
  design), and the mistake surfaced as a run-time `TypeError` in `Array.join` → declared the fields in the
  order `new` is called with, and wrote that in the class comment. A `new` by keywords
  (`OpenURIMeta.new(body: b, status: s, ...)`) would have avoided it; Sake has it for `new`, but I reached
  for the positional form out of Ruby habit.
- `while io == nil ... end` to loop over redirects, then `io.OpenURIMeta.base_uri = uri`: after the loop the
  checker knew `io` was not nil, good. But with a type error inside the body, the checker dropped the
  body's later assignments and reported `set_base_uri: argument 1 ... is nil` *instead of* the real error
  (repro: `open_uri_bug_while_body_after_type_error.sake`, reduced form shows the extra report; the
  full-library form showed only the wrong one).
- Ruby's `URI.open(url, redirect: false)` becomes `OpenURI.open(url, Hash[:redirect => false])`; the Hash
  mixes String keys (headers) and Symbol keys (options) with String, Boolean, Integer and Tuple values,
  which the typer accepted without a report (values of a Hash are a union).
- `String.scan(s, re)` with groups gives an Array of Tuples whose unmatched groups are nil; destructuring
  `|att, qval, val|` and `att || ""` worked, but every element is `String | nil` for the rest of the block.
- `_option(options, :redirect) != false` reads oddly compared with Ruby's `options.fetch(:redirect, true)`;
  there is no `Hash.fetch` on a possibly nil Hash without a check first.
