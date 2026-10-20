# rails_activesupport_b: ActiveSupport 8.1.3, part B (2026-10-20)

Callbacks, class_attribute, rescuable, CurrentAttributes, notifications (fanout, instrumenter, Event), Subscriber,
LogSubscriber, ActiveSupport::Logger (with LoggerSilence and LoggerThreadSafeLevel), TaggedLogging,
BroadcastLogger, MessageVerifier and MessageEncryptor (with Messages::Codec/Metadata), KeyGenerator, SecurityUtils, ParameterFilter,
and the generators that turn class bodies into Sake. Under `sakelib/rails/activesupport/active_support/`;
tests in `test/sakelib/rails/activesupport/` (`ruby -Ilib test/test_sakelib.rb -n /rails_activesupport_/`).

## The central question: stored callbacks without stored blocks

Rails stores code: `set_callback :save, :before, :normalize` becomes a lambda that `send`s `:normalize`;
`subscribe("sql") { |e| }` stores the block; `rescue_from E, with: :h` stores a pair and calls `method(:h)`. Sake
has no stored blocks, no `send`, no `method`, and no code in a class body. The answer has three parts:

1. **The chain is data, as in Rails.** `CallbackChain`, `Callback`, `CallbackSequence`, `Filters::Before/After`,
   `compile`, `run_callbacks` with around nesting, `skip_callback` with `if:`/`unless:` merging, `prepend:`,
   duplicate removal, `throw :abort`, `skip_after_callbacks_if_terminated`, `halted_callback_hook` are ported
   path by path from callbacks.rb. What a lambda held (the method name) is a Symbol in the data.
2. **The includer has one function that calls a method by its name** (Ruby's `target.send(filter)`), and one for
   around callbacks (`target.send(filter, &block)`, whose yield runs the rest of the chain). These are the only
   places the program's method names appear as code, so the checker checks every callback method (a misspelled
   `:normalise` is `undefined function normalise` before anything runs; Rails finds it on the first save).
3. **The class body is a file the generator reads.** The same file Ruby requires (`callbacks_decl.rb`):

```ruby
# callbacks_decl.rb (Ruby requires it; Sake's `generate` reads it)
class Post
  include ActiveSupport::Callbacks
  define_callbacks :save, :destroy
  set_callback :save, :before, :check
  set_callback :save, :before, :normalize, if: :title?
  set_callback :save, :around, :wrap
  set_callback :save, :after, :audit, unless: [:draft?, :quiet?]
end
class Draft < Post
  skip_callback :save, :before, :normalize
  set_callback :save, :after, :notify, prepend: true
end
```

```ruby
# generated (bin/sake --dump=generated, or test/sakelib/rails/activesupport/generate.sake)
def Post.__callbacks(t) = Post.__class_callbacks                    # class_attribute :__callbacks
def Post.__callback(t, filter)                                      # target.send(filter)
  case filter
  in :check then check(t)
  in :normalize then normalize(t)
  in :title? then title?(t)
  ...
  else raise ArgumentError, "undefined method '#{filter}' for an instance of Post"
  end
end
def Post.__around_callback(t, filter)                               # target.send(filter, &block)
  case filter
  in :wrap then wrap(t) { yield }
  ...
def Post._run_save_callbacks(t, &b) = run_callbacks(t, :save, &b)   # define_callbacks' module_eval
def Post.__class_callbacks = once do                                # the class body, line by line
  c = ActiveSupport::Callbacks::ClassMethods.new_callbacks
# sake-origin: callbacks_decl.rb:7
  ActiveSupport::Callbacks::ClassMethods.set_callback(c, :save, :before, :check)
# sake-origin: callbacks_decl.rb:8
  ActiveSupport::Callbacks::ClassMethods.set_callback(c, :save, :before, :normalize, {if: :title?})
  ...
  c
end
def Draft.__class_callbacks = once do
  c = ActiveSupport::Callbacks::ClassMethods.inherit(Post.__class_callbacks)   # the subclass's copy
  ActiveSupport::Callbacks::ClassMethods.skip_callback(c, :save, :before, :normalize)
  ...
```

And the program, side by side:

```ruby
# Ruby                                         # Sake
class Post                                     class Post
                                                 attr_accessor title, draft, quiet
                                                 include ActiveSupport::Callbacks
  def normalize                                  def normalize(r)
    self.title = title.strip                       @title = String.strip(@title)
  end                                            end
  def wrap                                       def wrap(r)
    puts("  wrap {"); yield; puts("  } wrap")      puts("  wrap {"); yield; puts("  } wrap")
  end                                            end
  def save                                       def save(r)
    run_callbacks(:save) { true }                  run_callbacks(r, :save) { true }
  end                                            end
end                                            end
                                               generate "rails/activesupport/active_support/generate/active_support", "callbacks_decl.rb"
p(Post.new(" Hello ").save)                    p(Post.save(Post.new(" Hello ")))
p(Draft._save_callbacks.map { [_1.kind, _1.filter] })   p(Enum.map(Draft._save_callbacks) { |c| [Callback.kind(c), Callback.filter(c)] })
```

The same can be written by hand (callbacks.sake's `Admin`: the two functions and a `once`), which is what a
class with two callbacks may prefer. **For the second wave**: ActiveModel's `define_model_callbacks` /
`before_save :x` and ActionController's `before_action :x, only: [...]` map their lines onto these
declarations (`before_save :x, if: :y` → `set_callback :save, :before, :x, if: :y`; that mapping is what
`CurrentAttributes::Generate.expand` does for `before_reset`/`resets`, so copy it). AbstractController's
terminator lambda `->(controller, result_lambda) { result_lambda.call; controller.performed? }` is recognised and
becomes `terminator: :performed?` (a method asked after each before callback). `only:`/`except:` become an object
condition: a class that includes `ActiveSupport::Callbacks::Conditionals::Filter` and defines `match?(f, target)`
(Rails' ActionFilter, which Ruby calls through `before`/`after`/`around`); callbacks.sake's test has one
(`OnlyActions`).

**The same shape for the other stored code:**

| Ruby | Sake |
|---|---|
| `class_attribute :x, default: 1` (singleton methods, redefined on write) | generated `def C.__class_attr_x = once { Slot.new(1, true) }`, `C.x`, `C.set_x(v)`, `C.x?`; a subclass reads its parent's until it writes (`Slot.read(own, Parent.x)`) |
| `rescue_from NotFound, with: :h` (pairs + `const_get(name) === e` + `method(:h)`) | the pairs are data (names as Strings, as Rails stores them); generated `__rescue_match?(t, name, e)` (`case name in "NotFound" then e in NotFound`) and `__rescue_call(t, handler, e)` |
| `attribute :user, default: x`, `before_reset`/`resets` | fields + generated `C.instance` (once), `__reset_attributes`, and the reset callbacks through the callbacks generator |
| `subscribe("sql") { \|event\| }` / `{ \|name, start, finish, id, payload\| }` / an object with `start`/`finish` | an object whose class includes `ActiveSupport::Notifications::Listener` and says its kind: `call(l, event)` (default), `listener_kind = :timed` + `call_timed(...)`, `listener_kind = :evented` + `start`/`finish`. Fanout's reflection (`respond_to?`, arity) is the `listener_kind` function. Listeners are stored as `Listener[]` and called by module dispatch (`Listener.call(l, e)`) |
| `class Sub < ActiveSupport::Subscriber; def sql(event)` + `attach_to :active_record` (public_methods) | `include ActiveSupport::Subscriber` with `__events(s) = Symbol[:sql]` and `__event(s, method, event)` (a `case`), written by hand: the method list is in the class, not in a class-body line, so no generator can see it |
| `ActiveSupport::TaggedLogging.new(logger)` (clone + `extend` the logger and its formatter) | the tag stack is a field of `ActiveSupport::Logger`; `TaggedLogging.new` sets it on a `dup` |

**Concern** (`extend ActiveSupport::Concern`, `included do`, `class_methods do`) has no file: a concern is a Sake
mixin module (`include M`), its instance methods are the module's functions with the instance first, its
`ClassMethods` are functions of the generated class functions or a `module_function` part of the module (as
`ActiveSupport::Callbacks::ClassMethods`), and its `included do ... end` block is class-body lines: either lines
a generator knows (`define_callbacks`, `class_attribute`) or, for the mixin's own state, the required functions the
includer defines (`__callbacks`, `__rescue_handlers`). A mixin can include a mixin
(`CurrentAttributes` includes `Callbacks`, `LogSubscriber` includes `Subscriber` includes `Listener`), and an
includer's function overrides the mixin's (that is how `halted_callback_hook`, `listener_kind`, `silenced?` work).
What Concern's dependency resolution does is not needed: there is no `append_features` order to fix.

All generators share one parser (`generate/class_body.sake`: class/end, one declaration per line, Ruby
literals: Symbols, Strings, numbers, true/false/nil, Arrays, `{}`, constants) and one program
(`generate/active_support.sake FILE...`), which rejects a line no generator knows and a block or lambda
(`` `-> { published? }` has no Sake form here (a block or a lambda: name a method instead) ``). Railties can call
the functions directly (`ActiveSupport::Callbacks::Generate.class_source(body, bodies, path)`, ...).

## What is ported

| Ruby (activesupport-8.1.3/lib/active_support/) | Sake | Ruby code lines | Sake code lines |
|---|---|---|---|
| callbacks.rb | callbacks.sake | 570 | 355 |
| core_ext/class/attribute.rb, class_attribute.rb | core_ext/class/attribute.sake | 89 | 15 |
| rescuable.rb | rescuable.sake | 91 | 41 |
| current_attributes.rb | current_attributes.sake | 104 | 32 |
| notifications.rb | notifications.sake | 45 | 34 |
| notifications/fanout.rb | notifications/fanout.sake | 366 | 219 |
| notifications/instrumenter.rb | notifications/instrumenter.sake | 166 | 74 |
| subscriber.rb | subscriber.sake | 76 | 50 |
| log_subscriber.rb | log_subscriber.sake | 103 | 91 |
| logger.rb, logger_silence.rb, logger_thread_safe_level.rb | logger.sake (+ TaggedLogging::TagStack) | 110 | 97 |
| tagged_logging.rb | tagged_logging.sake | 104 | 55 |
| broadcast_logger.rb | broadcast_logger.sake | 108 | 68 |
| security_utils.rb | security_utils.sake | 22 | 13 |
| key_generator.rb | key_generator.sake (on the OpenSSL::PKCS5 built-in) | 38 | 27 |
| messages/codec.rb, messages/metadata.rb | messages/codec.sake | 206 | 73 |
| message_verifier.rb | message_verifier.sake | 93 | 77 |
| message_encryptor.rb | message_encryptor.sake (third wave, on the OpenSSL::Cipher built-in) | 144 | 106 |
| parameter_filter.rb | parameter_filter.sake | 82 | 55 |
| **total** | | **2,517** | **1,482** |
| (Sake only) Kernel#throw/catch | throw.sake | | 11 |
| (Sake only) the class-body side of callbacks, class_attribute, rescuable, current_attributes | generate/{class_body,callbacks,class_attribute,rescuable,current_attributes,active_support}.sake | | 385 |

Code lines: without blank and comment lines. Rails' line counts include parts left out (below), so the ratio is
not a compression ratio.

Tests (each `.sake` and `.rb` print the same; `generate.sake` prints the generated source and has no twin):
callbacks (+ callbacks_decl.rb), class_attribute (+ _decl.rb), rescuable (+ _decl.rb), current_attributes
(+ _decl.rb), notifications, log_subscriber, logger, message_verifier (with KeyGenerator), message_encryptor (third wave), parameter_filter,
generate. 1,138 lines.

Check time (`/usr/bin/time -f "%es %MKB" bin/sake -c --strict`, load average ~4 on the machine): callbacks.sake
**2.03 s, 62 MB** (the largest: it runs the generator stage, then checks the program with three includers of
Callbacks), message_verifier 1.47 s, current_attributes 1.46 s, rescuable 1.32 s, log_subscriber 1.31 s,
notifications 1.28 s, the others ~1.1 s.

## What is left out, and why

- **Block, lambda, String and object filters** in callbacks (`before_save { }`, `if: -> { }`, `before_save
  AuditCallbacks.new`): no stored blocks; name a method. Object *conditions* are supported (Conditionals::Filter).
- **A parent's set_callback after a subclass took its copy** (Rails' `__update_callbacks` over descendants): the
  class bodies run in order at first use, so this only matters for callbacks added at run time.
- **Instance readers/writers of class_attribute** (`obj.setting`): `C.setting` and `C.setting(obj)` would be one
  name with two arities, which Sake does not allow; the class's value is read as `C.setting`.
- **ActiveSupport::Configurable**: deprecated in 8.1 ("deprecated without replacement, and will be removed in
  Rails 8.2"), so not ported.
- **Per-thread state** (IsolatedExecutionState): the notifier's handle stack, the logger's local level and tag
  stack, CurrentAttributes' instance are one per program. Requests are served one at a time in the 10-12 server.
- **Serializers**: MessageVerifier and MessageEncryptor use `::JSON` only, with the metadata envelope inside the message (Rails 7.1's
  `use_message_serializer_for_metadata = true`); no Marshal, MessagePack, `:json_allow_marshal` fallbacks, no
  rotation (`Messages::Rotator`, `rotate`).
- **Cache stores** (Store, Entry, MemoryStore, FileStore, NullStore, LocalCache), **ErrorReporter**,
  **Deprecation**, **lazy_load_hooks**, the **i18n railtie / locale/en.yml**, **Executor/Reloader**: not done (time).
  The shapes are known: a store is a class with the Store functions (fetch's block is an ordinary yield); an
  error-reporter subscriber and a load hook are Listener-like objects; Executor's to_run/to_complete are the
  callbacks above.
- **Event#allocations / gc_time** are 0 (no allocation or GC counters in Sake); cpu_time is the process's.
- **Subscriber's method_added** (subscribe a method defined after attach_to) and LogSubscriber's
  `subscribe_log_level`.

## Built-ins Sake lacks (requests)

All the requests below except throw/catch's values landed in the built-ins wave; the third wave (part 10) moved
the port onto them (see "Third wave" at the end).

- **A cipher**: `OpenSSL::Cipher` AES-256-GCM (and CBC) for MessageEncryptor and the encrypted cookie jar. (Landed.)
- **PBKDF2**: `OpenSSL::PKCS5.pbkdf2_hmac` / `OpenSSL::KDF.pbkdf2_hmac`. Written in Sake over sakelib's HMAC it was
  correct (the keys match Ruby's) but one HMAC-SHA1 was ~20 ms, so Rails.application.key_generator's 1000
  iterations took ~20 s per key and ActiveSupport's default 2**16 about 20 minutes. (Landed; the default now takes
  well under a second, and the test derives one key with it.)
- **throw/catch**: written as `throw.sake` (an exception class), without a thrown value. Callbacks need only
  `throw :abort`; the message codecs throw values, which became three exception classes.
- **The class name of a value** (`e.class.name`): Notifications' `payload[:exception]`, InstrumentationSubscriberError's
  message and the log subscriber's error line need it; `Notifications.class_name(e)` parsed `Kernel.inspect(e)`.
  (Landed as `Kernel.class_name`.)
- **`Regexp[]`** (a typed Array of Regexps): ParameterFilter kept its patterns in `Any[]`. (Landed.)

## Bugs and surprises (repros in experiments/2026-10-20-rails-scale/bugs/)

- `activesupport_b_module_pattern_without_includers.sake`: `in M` for a module no type includes is an error
  (`no type includes Filter`). A library that matches "an object of a type including M" breaks every program that
  defines none. Found when current_attributes.sake (no condition objects) failed after callbacks.sake passed.
  Workaround: `else` for the module case.
- `activesupport_b_generated_before_own_classes.sake`: generated source is read like a required file, before the
  file that has the `generate`, so a generated `class Post ... end` becomes the first `class Post` and the
  program's own `class Post` with fields is rejected. Consistent with the spec, but it means a generator can only
  add `def Post.f` functions; worth a line in the spec. The first generator (reopening `class Post` with
  `include`) hit this.

## Friction (what I wrote first → the message → what I wrote instead)

1. `class Record` in the first callbacks test → `` `Record` is a built-in type, so `class Record` only adds
   functions to it `` → `Post`. A Rails-ish name taken by the language.
2. `in {if:} then p(if)` → a syntax error (`if` is a keyword) → `in {if: c}`. Rails' option names `if:`/`unless:`
   cannot be bound by shorthand; `Record.to_h(opts)[:if]` is what the port uses.
3. `protected attr_reader chain` → "only def, include, ... are allowed in a class/module body" → `private`.
4. `Array.include?(CALLBACK_FILTER_TYPES, first)` inside the module → `` type `CALLBACK_FILTER_TYPES` cannot be used
   as a value `` → `ClassMethods.CALLBACK_FILTER_TYPES` (a constant is a function, and a bare uppercase name is a type).
5. `def before(s, b = nil)` as both reader and adder (Ruby reads `@before` directly) → a wall of `[mixed]` errors
   (`Array.push: an element must be CallbackSequence, but can be nil | Filters::Before[]...`) because the return type
   mixed the Array and the sequence → a reader `before_` and an adder `before`.
6. One dispatcher for all callbacks, always called with a block → `Admin.__callback does not take a block (it has no
   yield)` for a class without around callbacks → two functions: `__callback` (no block) and `__around_callback`,
   whose default in the mixin raises and then `yield`s, only so that the chain may pass it a block.
7. `env.value = !halted && (!block_given? || yield)` → `yield: no block is given on this call` (the checker does not
   follow `!block_given? ||`) → `(block_given? ? yield : true)`, and the inner sequence got two calls, with `{ yield }`
   and with `{ true }`.
8. A condition list built from `options[:if]` (the options Hash's values are Symbol | Array | true/false) →
   `Conditionals::Filter.match? dispatches on its first argument, which can be true|false` → reject booleans
   explicitly before pushing. A Hash of options gives every value the union of all options' types.
9. `rescue UncaughtThrowError => e` in `catch` → `warning: ... the begin body never raises UncaughtThrowError
   [unused-rescue]` in every program that never throws → `rescue => e` + `raise e unless e in UncaughtThrowError`.
10. The generator emitting `class Post; include ActiveSupport::Callbacks; ...` → `the fields of Post are declared in
    its first class Post` and `undefined function check` (see Bugs) → generated code is `def Post.f` only, and the
    app writes `include ActiveSupport::Callbacks` itself, as a Rails app does.
11. `e = ActiveSupport::Notifications::Event` as a local alias in a function → `` type ... cannot be used as a value ``
    → a top-level constant `E = ActiveSupport::Notifications::Event` (allowed: a type alias).
12. `def publish(name, *args) = Fanout.publish(notifier, name, *args)` → `splat arguments go only to a *rest
    parameter` → the five arguments written out.
13. `x if pat in Regexp && Regexp.match?(...)` → `` `&&` applies to the whole `... if ...` here `` (with the exact fix) →
    `(pat in Regexp) && ...`. Hit three times; the hint is good every time.
14. `code = color in Symbol ? a : b` → a syntax error with the hint `` `x in T` needs its own parentheses `` → fixed at once.
15. `ActiveSupport::Logger` with `def level(l) = @local_level || @level` (Rails' LoggerThreadSafeLevel overrides
    `level`) → not possible: `level` is the field's reader → `effective_level`, and `add`/`debug?`... re-ported to use it
    (the pasted ::Logger functions read `@level`).
16. tagged_logging.sake reopening `class Logger` and logger.sake requiring it → logger.sake's `class Logger < ::Logger`
    became the second class (`` `<` goes on the first class ``): a required file is read first. → TagStack moved into
    logger.sake; tagged_logging.sake requires logger.sake, not the reverse.
17. `Array.pop(@tags, count)` → `wrong number of arguments for Array.pop (given 2, expected 1)` → a loop.
18. `Regexp[]` → `Regexp has no typed Array` → `Any[]` (the element type is still inferred as Regexp).
19. `in "StandardError" then e in StandardError` → `` `StandardError` is not a type `` → `true` (rescue_from
    StandardError catches every exception; there is no common parent to test).
20. `Time.iso8601(string)` (parse) → `argument 1 must be Time, but is String` → `Time.xmlschema(s)` (sakelib/time's
    name for Ruby's parse; `Time.iso8601(t, 3)` is the built-in formatter).
21. `p(post)` of an object prints `#<struct Post title="x">` where Ruby prints `#<Post:0x... @title="x">`: tests print
    fields.

What read well: the callback chain's port is almost line for line (CallbackSequence, compile's `inject` over the
reversed chain, invoke_before/after, the skip list), and the checker caught real mistakes in it (the reader/adder
mix, a nil `@before`). Module dispatch (`Listener.call(l, e)` over `Listener[]`) is Ruby's duck typing for
subscribers, with the kinds named instead of found by reflection (a listener that forgets its `call` still fails
only when an event reaches it: the mixin's defaults raise, as Ruby's NoMethodError would). The decl files are shared verbatim with Ruby: one source of truth for both runs. The generated
code is ordinary Sake with `# sake-origin:` lines, so `set_callback :save, :before, :normalise, if: :title?` (a
typo) is `callbacks_decl.rb:8: error: undefined function normalise / hint: did you mean normalize?` before anything
runs (checked). What read badly: instance-first calls on the class-level things Rails makes
look global (`Current.user(Current.instance)` for `Current.user`; `ActiveSupport::Callbacks::ClassMethods.skip_callback(Post.__class_callbacks, ...)`
for `Post.skip_callback(...)`), and names doubled to avoid one name per function (`set_level`/`effective_level`).

## Third wave (part 10): the built-ins in place of the workarounds

| workaround (first wave) | now |
|---|---|
| PBKDF2 over OpenSSL::HMAC in key_generator.sake (`KeyGenerator.pbkdf2_hmac`, 13 lines) | `OpenSSL::PKCS5.pbkdf2_hmac`, Ruby's call. message_verifier's test adds a key with the default 2**16 iterations: the whole test runs in 1.3 s |
| `Notifications.class_name(e)` matching `/\A#<((?:\w\|::)+)/` on `Kernel.inspect(e)` | `Kernel.class_name(e)` (the function stays, a one-liner, since fanout/instrumenter/log_subscriber call it) |
| `class ActiveSupport::NoMethodError < StandardError` (string_inquirer.sake); `DelegationError < StandardError` | the built-in `NoMethodError`; `DelegationError < NoMethodError` as Ruby's. The tests rescue `NoMethodError` (delegation's also prints the class of a DelegationError caught as one) |
| ParameterFilter's `Any[]` of compiled patterns | `Regexp[]` (the filters given stay `Any[]`: Strings, Symbols and Regexps) |
| no MessageEncryptor | `message_encryptor.sake`: Rails' encrypt/decrypt/extract_parts/length_after_encode on OpenSSL::Cipher, AES-256-GCM (iv--tag) and AES-256-CBC signed by a MessageVerifier, purpose/expiry metadata, url_safe. The keyword API is the one ActionDispatch's encrypted jar was written against (`encrypt_and_sign(e, v, purpose:, expires_at:)`). Ruby's `catch_and_raise :invalid_message_format, as: InvalidMessage` / `catch_and_ignore :invalid_message_content` are rescues of codec.sake's exceptions |

The message_encryptor test decrypts three messages the real gem made (GCM with a purpose, CBC, url_safe GCM: the
IV is random, so they are fixed in both files), round-trips with purpose/expiry, and prints Rails' messages for a
tampered body (`invalid base64`), a tampered tag and a wrong key (`AEAD authentication tag verification failed`),
a truncated tag and a missing separator, a CBC signature mismatch (`mismatched digest`), and a short key
(`key must be 32 bytes`); then a key from KeyGenerator with Rails' 1000 iterations and the encrypted cookie salt.
It printed what the gem prints on the first run.

Check times (`bin/sake -c --strict`, load ~1.5), before → after: message_verifier 1.09 → 1.13 s (one more key),
notifications 1.08 → 1.07 s, log_subscriber 1.15 → 1.11 s, parameter_filter 0.93 → 0.92 s, delegation 0.93 → 0.87 s,
string_inquirer 0.79 → 0.72 s; message_encryptor (new) 1.19 s, 54 MB.

Friction and a checker bug:
- MessageEncryptor's `initialize` called `new_cipher(e)` (Ruby's `@aead_mode = new_cipher.authenticated?`), and
  `decrypt` calls it again → `warning: rescue ActiveSupport::Messages::InvalidMessageContent: the begin body never
  raises ... [unused-rescue]` on decrypt_and_verify, although the run rescued it. `bin/sake --types` listed
  everything after decrypt's `new_cipher` call as dead: when a function that `initialize` calls is called again
  later, the checker treats the code after the later call as unreachable, and does not check it (a `1 + "x"`
  there passes `-c --strict`). Repro `bugs/activesupport_call_after_initialize_callee_unchecked.sake`. Worked around
  by writing `OpenSSL::Cipher.new(@cipher)` in initialize. Other ports may have code hidden the same way.
- Ruby's test needed `require "active_support/core_ext/time"` for `expires_in:` (Metadata calls `Time#advance`),
  which a plain `require "active_support"` does not load; Sake's codec adds seconds to `Time.now`.
