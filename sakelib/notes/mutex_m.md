# mutex_m

`sakelib/mutex_m.sake`: Ruby's `Mutex_m`, a mixin giving a type `mu_lock`, `mu_unlock`, `mu_try_lock`,
`mu_locked?`, `mu_synchronize` and the unprefixed `lock`, `unlock`, `try_lock`, `locked?`, `synchronize`.
10 functions. The test prints 16 lines, identical to `mutex_m.rb`.

Sake's Mutex has only `synchronize`, so the lock inside is a `Monitor` from `sakelib/monitor.sake`, used without
re-entry (see `notes/monitor.md` for the construction and for `me`, the optional thread identity).

## API

| Ruby | Sake | |
|---|---|---|
| `include Mutex_m` (`mu_initialize` makes `@mu_mutex`) | `private attr_accessor mu_mutex`, `@mu_mutex = Monitor.new` in initialize, `include Mutex_m` | differs: the field is the type's |
| `mu_lock`, `lock` | `C.mu_lock(c, me = nil)` | same; with `me`, locking twice raises `ThreadError "deadlock; recursive locking"` as Ruby; without, the second lock waits forever |
| `mu_unlock`, `unlock` | `C.mu_unlock(c, me = nil)` | same; `ThreadError` "Attempt to unlock a mutex which is not locked" / "... locked by another thread/fiber" (the second only with `me`) |
| `mu_try_lock`, `try_lock` | `C.mu_try_lock(c, me = nil)` | same: false whenever the lock is held, by anyone |
| `mu_locked?`, `locked?` | same | same |
| `mu_synchronize { }`, `synchronize { }` | `C.mu_synchronize(c, me = nil) { }` | same |
| `Mutex_m.define_aliases`, `extend_object`, `mu_initialize` | | missing (Ruby's metaprogramming) |

## Built-ins needed

As `monitor`: `Thread.current`, and `Mutex.lock/unlock/try_lock/locked?/owned?`, which would make this file a
10-line wrapper over the built-in Mutex instead of a wrapper over a Monitor written in Sake.

## Friction

1. None new: written after `monitor` and correct on the first run. `require "monitor"` from a sakelib file
   finds `sakelib/monitor.sake` (relative to the requiring file), as hoped.
2. A mixin that defines `synchronize`, `lock`, `unlock` is fine next to the includer's own functions: the
   includer's definitions win (§5.5), as in Ruby.
