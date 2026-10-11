# useragent

`require "useragent"` → `sakelib/useragent.sake`, after the useragent gem 0.16.11. Test:
`test/sakelib/useragent.{sake,rb}`, 78 identical lines: 30 user agent strings (every browser class,
bots, curl, the empty string) and the classes' own methods, Version and UserAgent comparison, errors.

## Shape

Ruby's `UserAgent.parse` returns an instance of a subclass of Array (`Browsers::Chrome < Browsers::Base
< Array`), picked by `Browsers.extend` from the first class whose `extend?` accepts the products. Here:

- each browser is a class with one field `agents` (the Array of `UserAgent` products) that does
  `include Browsers::Base`; `Base` is a mixin module, so `UserAgent::Browsers::Base.browser(ua)` dispatches
  to the browser's own `browser` (Ruby's `ua.browser`); `UserAgent.parse` returns the union of the 15
  classes and every `Base` operation accepts it;
- Ruby's plain `Browsers::Base` instance (nothing recognized: curl) is `Browsers::Generic`;
- Ruby's `super` (Gecko#browser, Gecko#version, ITunes#os, ITunes#build, Libavformat#version) calls the
  Base or Webkit definition under another name: `base_browser`, `base_version`, `webkit_os`, `webkit_build`;
- `class ITunes < Webkit` copies Webkit's fields and functions, as Ruby's subclass does.

## API

| Ruby | Sake | |
|---|---|---|
| `UserAgent.parse(s)` | `UserAgent.parse(s)` | same (nil or blank → `"Mozilla/4.0 (compatible)"`) |
| `ua.browser` / `version` / `platform` / `os` / `mobile?` / `bot?` | `UserAgent::Browsers::Base.browser(ua)` / ... | same |
| `ua.to_s`, `ua.to_h`, `ua.to_a`, `ua.first`, `ua.last`, `ua.length`, `ua.application` | `Base.to_s(ua)`, ... | same (`to_a` gives the products; other Array methods: through `Base.to_a`) |
| `ua < other`, `>`, `==` | same operators | same: false when the browsers differ |
| `ua.chrome`, `ua.respond_to?("Iron")` (method_missing) | `Base.detect_product(ua, "chrome")` | differs: an operation (Ruby's private helper made public); no method_missing in Sake |
| `ua.build`, `security`, `localization`, `webkit` | `UserAgent::Browsers::Webkit.build(ua)` (the class's own) | same; the value must first be narrowed: `ua => UserAgent::Browsers::Webkit` |
| IE: `trident_version`, `real_version`, `compatibility_view?`, `chromeframe` | `UserAgent::Browsers::InternetExplorer.trident_version(ie)` ... | same; `real_version` without a Trident version gives the version (Ruby raises sorting `[nil, v]`) |
| ITunes `full_os`; PodcastAddict `device`, `device_build`; WMP `wmfsdk_version`, `has_wmfsdk?`, `classic?` | same, on the class | same |
| `UserAgent.new(product, version = nil, comment = nil)` | `UserAgent.new(product, version, comment)` | same (Strings; comment split at `"; "`); nil product → ArgumentError, Ruby's message |
| `product.product` / `version` / `comment`, `detect_comment { }`, `eql?`, `to_s`, `to_str` | `UserAgent.product(p)`, ... | same |
| `UserAgent::Version.new(s)`, `nil?`, `to_a`, `to_s`, `inspect`, `==` (String/nil), `<=>`, `<` ... | same | same; `Version.new(version)` (Ruby returns it) is `UserAgent.version_of(x)` |
| `UserAgent::OperatingSystems.normalize_os(s)` | same | same (nil → nil) |
| `UserAgent::Comparable` | `UserAgent::PartialComparable` | differs: name (a checker bug, below) |
| `Browsers::Security`, `Browsers::ALL`, `Webkit::BuildVersions`, `*::ChromeBrowsers` | `Browsers.security(k)`, functions | differs: no value constants |

About 50 operations.

## What differs and why

- **No Array subclass.** A Sake class cannot be an Array, so the products are a field; `Base.to_a(ua)`
  gives them. The dispatch Ruby gets from the class hierarchy comes from `include Base` (a mixin call
  `Base.f(ua)` runs the includer's `f`).
- **Browser-specific methods need narrowing.** Ruby calls `ua.trident_version` on whatever `parse`
  returned; Sake's `InternetExplorer.trident_version` takes an InternetExplorer, so the test writes
  `ie7 => UserAgent::Browsers::InternetExplorer` first (a blank line in the Ruby file).
- **Truthiness instead of `!= nil`** on UserAgent values (a bug, below): `l ? ... : false`.
- **`extend?` returns true/false** (Ruby returns the detected product or nil; used only as a condition).
- **PodcastAddict#platform** with no os: Ruby raises NoMethodError (`nil.include?`), here nil.
- **Opera's `mini?`** is Ruby's `/Opera Mini/ === application`, which matches the product's `to_str`;
  written as `String.match?(UserAgent.to_s(a), /Opera Mini/)`.

## Bugs found (repros in notes/)

- `useragent_bug_truthiness_calls_user_eq.sake`: a truthiness test (`u ? 1 : 2`, `u && x`, `if u`) of an
  instance whose class defines `==` calls that `==` with `false` (Values.truthy? does `v == false`). The
  first `l ? ... : false` here raised `TypeError: UserAgent.product: argument 1 must be UserAgent, got false`
  from inside `==`. Not caught by the checker. Workaround: `return false if Kernel.equal?(b, false)` at the
  top of both `==` functions.
- `useragent_bug_toplevel_comparable.sake`: a module named `Comparable` inside `class UserAgent` hides the
  built-in `Comparable` from operators even in a nested class that says `include ::Comparable`:
  `Comparable.<=>: Outer::V does not include Comparable`. Workaround: the module is `PartialComparable`.

## Built-ins Sake lacks (requests)

- A truthiness test that never calls user code (the bug above).
- `Regexp === value` calling `to_str` (Ruby's implicit conversion): not needed, but the gem relies on it.

## Friction (what I wrote → the message → what I wrote instead)

- `module Comparable` (Ruby's name) inside `class UserAgent` + `include ::Comparable` in Version →
  `Comparable.<=>: UserAgent::Version does not include Comparable` → renamed the module (bug above).
- `l != nil && UserAgent.product(l) == "Edge"` → no static error; at run time `UserAgent.product: argument 1
  must be UserAgent, but is nil` from inside `<=>` (my `==` derived from `<=>` got nil) → `l ? ... : false`,
  which then hit the truthiness bug → guard in `==`.
- Test line `UserAgent.to_s(Base.detect_product(chrome, "safari"))` → `UserAgent.product: argument 1 must be
  UserAgent, but can be nil | true|false` reported at nine lines inside the library's `to_s` and `<=>`, with
  only "reached by the call at line 53" pointing at the test; and `true|false` came from another call site
  (`chromeframe`). → `safari_product => UserAgent` in the test. The error belongs at the call.
- `p(x.inspect)` out of Ruby habit in an interpolation → the hint offered `Kernel.inspect(...)` and,
  oddly, `UserAgent::Version.inspect(...)` for a String-or-nil value.
- What went well: 15 browser classes over one mixin, with `include` overriding per class, read like the Ruby
  files; the first full run of the 30-agent table printed Ruby's output.

## Size

Ruby: 1530 lines (user_agent.rb + user_agent/**/*.rb; 1147 without comments and blank lines).
Sake: 1122 lines (920 without comments and blank lines).
