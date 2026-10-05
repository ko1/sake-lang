# ipaddr (Ruby's `require "ipaddr"`, ipaddr 1.2.8)

`sakelib/ipaddr.sake`: `class IPAddr` (fields `src`, `family`; private `addr`, `mask_addr`, `zone_id_`)
with about 45 public operations, the four exception types, and `Socket.AF_UNSPEC` / `AF_INET` /
`AF_INET6` added to the built-in `Socket`. The algorithms are ipaddr.rb's, line by line (parsing regexps,
`to_s` compression, `mask!`, the predicates). Test: `test/sakelib/ipaddr.{sake,rb}`, identical output with
`--strict` (also clean at `--strict=1 -c` and `--strict=2 -c`).

## API

| Ruby | Sake | |
|---|---|---|
| `IPAddr.new(s = "::")`, `IPAddr.new(int, Socket::AF_INET)` | `IPAddr.new(s)`, `IPAddr.new(int, Socket.AF_INET)` | same: `initialize` parses the first field (a String, or an Integer with a family), with `"[v6]"`, `"%zone"`, `"/len"`, `"/mask"` |
| `Socket::AF_INET`, `AF_INET6`, `AF_UNSPEC` | `Socket.AF_INET` ... | differs: functions (2, 10, 0, as Linux) |
| `IPAddr::InvalidAddressError`, `AddressFamilyError`, `InvalidPrefixError`, `Error` | `IPAddrInvalidAddressError` ... | differs: no nested names, and no hierarchy (Ruby: InvalidPrefixError < InvalidAddressError < Error < ArgumentError), so `rescue ArgumentError` or `rescue IPAddrInvalidAddressError` does not catch an InvalidPrefixError; list them. Messages same |
| `to_s`, `to_string`, `to_i`, `inspect`, `cidr`, `netmask`, `wildcard_mask`, `prefix`, `family` | `IPAddr.to_s(ip)` ... | same (`#<IPAddr: IPv4:192.168.1.0/255.255.255.0>`) |
| `ip.prefix = n`, `ip.zone_id = z` | `ip.IPAddr.prefix = n`, `ip.IPAddr.zone_id = z` | same (`def prefix=(ip, n)`) |
| `mask(len or "mask")`, `include?`, `===` | same | same (String / Integer / IPAddr argument) |
| `& \| ~ << >> + -` | same operators | same |
| `==`, `<=>`, `<` ..., `sort`, `max` | same | same (`include Comparable`); `ip == nil` is false, where Ruby's is true for `0.0.0.0` (nil.to_i) |
| `hash`, `eql?`: IPAddr as a Hash key | — | missing: Sake rejects keys of a type with its own `==` (spec §12.1). Key by `IPAddr.to_s` or `IPAddr.cidr` |
| `to_range` | `IPAddr.to_range(ip)` | differs: a Tuple `[first, last]` of IPAddr, since a Sake Range holds numbers and Strings only |
| `hton`, `IPAddr.ntop(bin)`, `IPAddr.new_ntoh(bin)` | same | same (`ntop` checks the binary encoding) |
| `ipv4? ipv6? loopback? private? link_local? ipv4_mapped? ipv4_compat?` | same | same |
| `ipv4_mapped ipv4_compat native reverse ip6_arpa ip6_int succ` | same | same |
| `as_json`, `to_json` | same | same |
| `zone_id` | same | same |
| `IPAddr.new` with a host name (`IPSocket.getaddress`) | — | missing, as in Ruby (it never resolves) |

Helpers (`in_addr`, `set!`, `mask!`, `coerce`, `begin_addr`, ...) are visible as `IPAddr.f`; Sake has no
private functions. The private fields have no reader, so `IPAddr.raw_mask(ip)` reads another instance's mask
inside `mask!`.

## Frictions (wrote first → message → wrote instead)

- `def set_prefix(ip, n)` expecting `ip.IPAddr.prefix = n` to reach it (it does for a field, whose writer is
  `set_x`) → `undefined function IPAddr.prefix=` → `def prefix=(ip, n)`. A field's writer is `set_x` and a
  setter function is `x=`, so the spelling depends on whether `x` is a field.
- `o != nil` after a `begin coerce(...) rescue ... nil end` → `case/in: no in branch matches nil`, inside
  `coerce`, reached from `==`: `!=` on an IPAddr runs IPAddr's own `==` with nil, as Ruby does → `(o in
  IPAddr)`, and `return false if (b in nil)` first in `==`. Correct, but surprising: with a user `==`,
  every `x == nil` check runs it.
- `re == /\A0:...\z/` inside the loop over `to_s`'s regexps, to pick `"::"` for the first → the first pattern
  never matched by `==` (`::` printed as `:`), no report → `Array.each_with_index` and `i == 0`. Bug:
  `Regexp == Regexp` is false even for the same object (Ruby: true), while `Array.include?` finds it.
  Repro: `notes/ipaddr_bug_regexp_equality.sake`.
- Ruby's `self.clone.set(...)` and `instance_variable_set(:@mask_addr, ...)` on the clone → `@x` only means
  the first parameter's field → small in-class functions that take the copy first:
  `copy_with(ip, addr, family)` = `set!(Kernel.dup(ip), addr, family)`, `widen_mask!(c, m)`.
- `Socket::AF_INET` → no nested names → functions added to the built-in `Socket` namespace (`class Socket`
  with `def AF_INET = 2` worked).

## Language features used

- **`initialize`** (helped most): Ruby's `IPAddr.new(addr, family)` is the field constructor plus
  `initialize`, which parses `@src` and sets the private fields; `IPAddr.new("10.0.0.0/8")` reads as in Ruby.
- **`private attr_accessor`** (helped): `addr`, `mask_addr`, `zone_id_` are internal, as Ruby's ivars.
- **Field defaults** (helped): `attr_reader src = "::", family = 0`, so `IPAddr.new` and `IPAddr.new(s)` are
  Ruby's defaults (`"::"`, `AF_UNSPEC`).
- **Optional parameter defaulting to a field**: `def set!(ip, addr, family = @family)`.
- **`x => T`** (helped): `family => Integer`, `src => String`, `mask => Integer`.
- **`once`** (helped): the three parsing regexps and the zero-run table.
- **`include Comparable` / `Bitwise` / `Arithmetic`** with `def <=>`, `def &`, `def ~(a)`, `def +` ...: all
  of Ruby's operators.
- Not needed: keyword arguments, `*rest`, `**opts`, `block_given?`, `&b`.

## Checker findings before the test passed

- `--strict=1 -c`: the two `undefined function IPAddr.prefix=` / `zone_id=` (static errors, above), then
  `case/in: no in branch matches nil` in `coerce` (the `!=` above). Both levels gave the same reports.
- `--strict=2 -c`: nothing more.

## `--types`

- Fields: `IPAddr.src: Integer | String` (Ruby's `IPAddr.new` takes either; `initialize` branches on it),
  `zone_id_: nil | String` (only IPv6 addresses with `%zone` have one). `family`, `addr`, `mask_addr` are
  `Integer`.
- No unknowns.
