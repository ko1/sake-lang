# Rails 8.1.3 part 5: ActiveModel (2026-10-20)

The rest of `activemodel-8.1.3/lib/active_model/` on the Arel agent's ActiveModel::Type and ActiveModel::Attribute
(described in `rails_arel.md`) and on ActiveSupport (`rails_activesupport_{a,b}.md`): Model/API, naming,
translation, conversion, attribute assignment, Errors/Error, Validations with every validator, model callbacks and
validation callbacks (both on ActiveSupport::Callbacks), the attributes API, AttributeMethods, Dirty,
Serialization/JSON and SecurePassword (on sakelib/bcrypt). Programs reach it as `require "rails/activemodel/active_model"`
plus one `generate` line per file of class bodies.

Tests (`ruby -Ilib test/test_sakelib.rb -n /rails_activemodel/`; each `.sake` prints what its `.rb` prints on the real
gem; the `_decl.rb` files are the class bodies both read):

| test | what | check (`bin/sake -c --strict`, load ~7) |
|---|---|---|
| `model` (+ model_decl.rb) | assign/build, UnknownAttributeError, slice, Name and naming functions, human_attribute_name, conversion, validations with errors' whole API, contexts, if:, a subclass, strict, validate!, i18n of model/attribute/messages | 4.6 s, 116 MB |
| `validations` (+ _decl) | every validator and its options/messages, a custom EachValidator (`email: true` style key) and Validator (validates_with), validates_*_of, validates!, except_on | 5.7 s, 124 MB |
| `callbacks` (+ _decl) | define_model_callbacks (before/around/after, only:), throw :abort, after skipped when the block returns false, before/after_validation with on: | 4.5 s, 112 MB |
| `attributes` (+ _decl) | typed attributes with defaults and casting, a custom attribute_method_suffix, Dirty on an AttributeSet and with `*_will_change!` (ForcedMutationTracker), alias_attribute, serializable_hash/as_json/to_json/from_json | **9.0 s, 183 MB** (the largest) |
| `secure_password` (+ _decl) | has_secure_password (two of them), authenticate, digest/confirmation/challenge/72-byte validations | 3.4 s, 95 MB |
| `generate` | prints the generated source (no twin) | 2.0 s |

(Measured with the machine at load 7.8, shared with the other agents; each time includes the generator stage.)
The bcrypt gem is not installed for Ruby here; `secure_password.rb` falls back to the same bcrypt over
`String#crypt` that sakelib/bcrypt.sake uses (only when `require "bcrypt"` fails; the printed values do not depend on it).

## What is ported

Code lines (no blanks, no comments). Ruby counts are whole files, left-out parts included.

| Ruby (activemodel-8.1.3/lib/active_model/) | Sake (sakelib/rails/activemodel/active_model/) | Ruby | Sake |
|---|---|---|---|
| naming.rb | naming.sake | 105 | 81 |
| translation.rb | translation.sake | 46 | 52 |
| error.rb, nested_error.rb | error.sake | 157 | 88 |
| errors.rb | errors.sake | 163 | 110 |
| validator.rb | validator.sake | 54 | 60 |
| validations.rb | validations.sake | 137 | 67 |
| validations/{presence,absence}.rb | validations/presence.sake | 28 | 14 |
| validations/length.rb | validations/length.sake | 61 | 74 |
| validations/numericality.rb | validations/numericality.sake | 126 | 111 |
| validations/format.rb | validations/format.sake | 50 | 48 |
| validations/{clusivity,inclusion,exclusion}.rb | validations/clusivity.sake | 76 | 61 |
| validations/{acceptance,confirmation}.rb | validations/acceptance.sake | 109 | 45 |
| validations/comparison.rb | validations/comparison.sake | 34 | 32 |
| validations/{helper_methods,resolve_value,comparability}.rb | validations/helper_methods.sake | 52 | 63 |
| validations/with.rb | validations/with.sake | 40 | 11 |
| validations/callbacks.rb | validations/callbacks.sake | 52 | 12 |
| callbacks.rb | callbacks.sake | 50 | 17 |
| conversion.rb | conversion.sake | 32 | 23 |
| attribute_assignment.rb, forbidden_attributes_protection.rb, access.rb | attribute_assignment.sake, forbidden_attributes_protection.sake, access.sake | 61 | 57 |
| api.rb, model.rb | api.sake | 27 | 16 |
| attribute_set.rb, attribute_set/builder.rb | attribute_set.sake | 243 | 49 |
| attribute/user_provided_default.rb (+ Attribute#with_type, #dup_or_share) | attribute/user_provided_default.sake | 53 | 30 |
| attribute_registration.rb | attribute_registration.sake | 90 | 19 |
| attribute_methods.rb | attribute_methods.sake | 236 | 19 |
| attributes.rb | attributes.sake | 58 | 25 |
| attribute_mutation_tracker.rb | attribute_mutation_tracker.sake | 147 | 103 |
| dirty.rb | dirty.sake | 122 | 63 |
| serialization.rb, serializers/json.rb | serialization.sake, serializers/json.sake | 76 | 107 |
| secure_password.rb | secure_password.sake | 93 | 42 |
| active_model.rb | ../active_model.sake | 66 | 19 |
| (validations/validates.rb, the class side of the files above) | generate/*.sake (Sake only) | (45) | 846 |
| (Sake only) Ruby's `send` on a model | send.sake | | 7 |
| **total** | 34 library files + 6 generator files | **2,678** | **1,525 + 846** |

`locale/en.yml` is copied verbatim and loaded at the first translation (`ActiveModel.load_locale`).
Tests: 425 Sake lines and 100 lines of class bodies, the `.rb` twins as long.

## How a model is written

The class body is a Ruby file that both sides read; the Sake program reopens the class for its methods, as a
Ruby app's class body and its methods would be one file:

```ruby
# model_decl.rb (Ruby: require_relative; Sake: generate "rails/activemodel/active_model/generate/active_model", "model_decl.rb")
class Person
  include ActiveModel::Model
  attr_accessor :id, :name, :email, :age, :role
  validates :name, presence: true, length: { maximum: 10 }
  validates :email, format: { with: /\A[^@\s]+@[^@\s]+\z/, message: "is not an email" }, allow_blank: true
  validates :role, inclusion: { in: %w[admin member] }, on: :create
  validate :not_reserved
  validates :id, absence: true, if: :guest?
end
```

```ruby
# Ruby (model.rb)                               # Sake (model.sake)
class Person                                    class Person
  def not_reserved                                def not_reserved(r)
    errors.add(:name, :reserved,                    ActiveModel::Errors.add(errors(r), :name, :reserved,
      message: "is reserved") if name == "root"        message: "is reserved") if @name == "root"
  end                                             end
  def guest? = role == "guest"                    def guest?(r) = @role == "guest"
end                                             end
pe = Person.new(name: "Ann", age: 3)            pe = Person.build(name: "Ann", age: 3)    # or Person.new(name: "Ann", age: 3)
pe.valid?                                       Person.valid?(pe)
pe.errors.full_messages                         ActiveModel::Errors.full_messages(Person.errors(pe))
pe.errors[:name]                                Person.errors(pe)[:name]
Person.model_name.human                         ActiveModel::Name.human(Person.model_name)
```

What the generator writes for it (`bin/sake --dump=generated model.sake`, or the `generate` test):

```ruby
class Person                                         # the first `class Person`: its fields and includes
  attr_accessor id, name, email, age, role
  private attr_accessor __errors, __context_for_validation      # Ruby's @errors, @context_for_validation
  include ActiveModel::Model
end
def Person.model_name = once { ActiveModel::Name.new("Person", nil, nil, :en, Person.lookup_ancestors, Person.i18n_scope) }
def Person.__send(r, __name)                         # Ruby's send(name): read_attribute_for_validation, slice, methods:
  case __name
  in :id then id(r)
  ...
  else __send_missing(r, __name)                     # NoMethodError, or the class's own __send_missing
  end
end
def Person._assign_attribute(r, k, v)                # Ruby's public_send("#{k}=", v) in assign_attributes
  case k
  in "name" then r.Person.name = v
  ...
  else attribute_writer_missing(r, k, v)             # UnknownAttributeError
def Person.__validator_1 = once { ActiveModel::Validations::LengthValidator.new(Hash.of(attributes: Any[:name], maximum: 10, class: "Person")) }
def Person.__validate_1(r) = ActiveModel::Validations::LengthValidator.validate(Person.__validator_1, r)
def Person._validators = once { Hash.of(:name => ActiveModel::AnyValidator[Person.__validator_0, Person.__validator_1], ...) }
def Person.__on_create?(r) = validation_context_in?(r, Symbol[:create])     # Ruby's predicate_for_validation_context lambda
# then ActiveSupport::Callbacks::Generate's output for these lines:
#   define_callbacks :validate, scope: :name
#   set_callback :validate, :__validate_1
#   set_callback :validate, :__validate_4, if: [:__on_create?]
#   set_callback :validate, :not_reserved
```

So Rails' validator objects stay objects (one `once` each, holding Rails' options Hash in Rails' order, which is
what `errors.details` prints), the :validate chain holds method names as ActiveSupport::Callbacks wants, and the
generated `__validate_N` is the stored object's `validate(record)`. `validates :email, email: true` finds
`EmailValidator` as Rails' const_get does (a program's class when ActiveModel has none of that name):

```ruby
# Ruby                                                        # Sake
class EmailValidator < ActiveModel::EachValidator              class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)                    def validate_each(v, record, attribute, value)
    record.errors.add(attribute, :taken) if ...                    ActiveModel::Errors.add(ActiveModel::Validations.errors(record), attribute, :taken) if ...
```

`<` pastes EachValidator's fields (options, attributes) and functions; the pasted `validate` calls this class's
`validate_each`. A model's validators of several classes are `ActiveModel::AnyValidator` values (a module every
validator includes; `AnyValidator.kind(v)` dispatches).

**Model callbacks** map onto ActiveSupport::Callbacks as Ruby's define_singleton_method bodies do:

| class body | callbacks line |
|---|---|
| `define_model_callbacks :save` | `define_callbacks :save, skip_after_callbacks_if_terminated: true, scope: [:kind, :name]` |
| `before_save :a, if: :b` | `set_callback :save, :before, :a, if: [:b]` |
| `after_save :c` | `set_callback :save, :after, :c, prepend: true, if: [:__callback_value_not_false?]` |
| `before_validation :d, on: :create` | `set_callback :validation, :before, :d, if: [:__on_create?]` |
| `after_validation :e` | `set_callback :validation, :after, :e, prepend: true` |

Ruby's `Conditionals::Value.new { |v| v != false }` (after_save does not run when the block returned false) needs
the block's value, which ActiveSupport's port does not give conditions; the generated `_run_save_callbacks` keeps
it (`ActiveModel::Callbacks.record_value`) and `__callback_value_not_false?` reads it. Through a direct
`run_callbacks(r, :save) { }` the after callbacks run whatever the block returned (see "Left out").

**Attributes** are an AttributeSet in the field `__attributes`, as Ruby's @attributes, with typed readers:

```ruby
# attribute :quantity, :integer, default: 1           # generated
def Product._default_attributes = once do              # Ruby's pending modifications applied in order
  s = ActiveModel::AttributeSet.new(Hash.new)
  ActiveModel::AttributeRegistration.apply_type(s, "quantity", ActiveModel::Type.lookup(:integer))
  ActiveModel::AttributeRegistration.apply_default(s, "quantity", 1)
  s
end
def Product.quantity(r)                                # Ruby: attribute("quantity"); here also narrowed
  v = attribute(r, "quantity")
  case v
  in ::Integer | nil then v
  else raise TypeError, "quantity is not ::Integer"
  end
end
def Product.quantity=(r, value)                        # `p.Product.quantity = "3"` casts, as in Ruby
  _write_attribute(r, "quantity", value)
end
def Product.quantity_changed?(r, **options) = attribute_changed?(r, "quantity", **options)   # Dirty's patterns
def Product.restore_quantity!(r) = restore_attribute!(r, "quantity")
```

AttributeMethods' AttributeMethodPattern (prefix/suffix/parameters/proxy_target) is ported in the generator; every
pattern's method is written for every attribute (Dirty's nine, Attributes' `=`, the class's
`attribute_method_suffix`/`_prefix`/`_affix`, alias_attribute's), which is Ruby's define_attribute_methods
done before the program runs instead of define_method plus method_missing. `Person.quantity(p)` is an Integer or
nil to the checker, which Ruby's reader is not.

## For ActiveRecord (and other includers)

ActiveRecord's model layer can include these modules into its own generated classes. What an includer must have:

| module | fields the class declares | functions the class (its generator) defines |
|---|---|---|
| Validations (also through API/Model/SecurePassword) | `__errors`, `__context_for_validation` | `__send(r, name)`, `__class_name`, `model_name`, `lookup_ancestors`, `_validators`, `__raw_value_for_validation(r, attr)` (ActiveRecord: `attribute_raw_value_for_validation(r, attr)`), `__callbacks`/`__callback`/`_run_validate_callbacks` (ActiveSupport::Callbacks::Generate) |
| Validations::Callbacks | | `_run_validation_callbacks(r) { }` |
| AttributeAssignment | | `_assign_attribute(r, k, v)`, `__class_name` |
| Conversion | | `persisted?(r)` (API: false), `__id(r)` when the class has an id |
| AttributeMethods / Attributes | `__attributes` (an AttributeSet; nil without Attributes) | `__send`, `attribute_aliases`, `_default_attributes` (Attributes), the attribute methods |
| Dirty | `__mutations_from_database`, `__mutations_before_last_save` (and `__attributes`) | `_assign_attribute` |
| Serialization / Serializers::JSON | | `__send`, `__attributes_for_serialization(r)` (= `attributes(r)`) |

`ActiveModel::Generate.program_source(text, path)` is the whole generator as a function; `collect`,
`class_source`, `naming_source`, `send_source`, `assign_source`, `ActiveModel::Validations::Generate.expand/source`
(with `known` listing validator namespaces: add `["ActiveRecord::Validations", String["uniqueness", ...]]`),
`ActiveModel::Callbacks::Generate.expand/run_source`, `ActiveModel::AttributeMethods::Generate.source` are the parts.
Ruby's class methods that also have an instance form are the class's (`Person.model_name`,
`Person.human_attribute_name(:x)`, `Person.attribute_names`), and the instance's are `_of`:
`ActiveModel::Naming.model_name_of(record)`, `ActiveModel::Translation.human_attribute_name_of(record, attr)`,
`ActiveModel::Attributes.attribute_names_of(record)` (one name is one function). ActionDispatch's polymorphic routes ask
for `route_key`/`singular_route_key`/`persisted?`/`to_param`: a model includes Naming (`route_key(r)`,
`singular_route_key(r)`) and Conversion (`to_param(r)`), so including `ActionDispatch::Routing::PolymorphicRoutes::Model`
and `ToParam` too makes a model a route argument (ActiveModel does not require actionpack, so it does not include them).

## Left out, and why

- **Blocks and lambdas in class bodies**: `validates_each :a do |r, attr, v|`, `validate do ... end`, `before_save { }`,
  `if: -> { }`, Proc options (`maximum: -> { }`), BlockValidator: no stored blocks; name a method (the generator says so
  at the line). Symbol options (`maximum: :limit`, `in: :choices`, `if: :x?`) work.
- **ActiveModel::Attributes::Normalization** (`normalizes :email, with: -> { }`): its whole input is a lambda.
- **AttributeSet::Builder, LazyAttributeSet, LazyAttributeHash, YAMLEncoder**: the database side (ActiveRecord builds its
  set from rows; the lazy forms are an optimization). Lint, Railtie, deprecator, `ActiveModel::Type` registration of new
  types (the Arel agent's `lookup` is a `case`).
- **`after_save` and a direct `run_callbacks(r, :save) { false }`**: the block's value reaches the after callbacks'
  condition only through the generated `_run_save_callbacks` (which ActiveRecord's own save calls).
- **`errors.add(:x, :y, message: -> { })`, Proc types, `strict: CustomError`** (a class is not a value): `strict: true` raises
  StrictValidationFailed. `Error#==`/`hash`, `copy!`, `deep_dup`.
- **WithValidator's arity**: `validates :x, with: :m` calls `m(record)`; Ruby also accepts `m(attr)` by reflection.
- **Plain-model Dirty's `respond_to?(:#{attr}_digest_was)`** and similar reflection: answered by the generator, which knows the
  class's methods.
- **Reset tokens of has_secure_password** (generates_token_for is ActiveRecord's), `include_root_in_json` as a writable class
  attribute (`self.include_root_in_json = true` in the class body becomes `def K.include_root_in_json = true`).
- **Error interpolation `%{object}`**: Ruby passes the record (`object: base`); here it is left out of the values, because a
  record in the values Hash made every value's type hold the record, and a `==` between that union and a Date failed in
  date.sake (fixed since in date.sake by the lead's 23307e9a; not re-added).
- **`Person.new(attrs)` running assign_attributes**: Sake's `new` stores fields, so `Person.new(name: "x")` is fine for
  attr_accessor fields and `Person.build(attrs)` (generated; ActiveRecord 7.1's name for new) assigns through the writers.
  A generated `initialize` exists in every model (an app cannot also define its own; use the writers).

## Built-ins

All the ones this part needed landed during the work (182d525f): `Kernel.class_name` (validators' `kind`, which first
parsed `Kernel.inspect`), `NoMethodError` (UnknownAttributeError is one, as in Ruby; `__send_missing` raises it),
sakelib/bcrypt (SecurePassword), throw/catch. Still asked for:
- **BigDecimal in ActiveSupport's `Object.as_json`** (Rails: `to_s`, "9.5"): serializers/json.sake converts them itself.
- **ActiveSupport's i18n `en.yml`** (number/date formats, `to_sentence` connectors) is not loaded by the activesupport port;
  ActiveModel's own `en.yml` is enough here.

## Bugs and surprises (experiments/2026-10-20-rails-scale/bugs/)

- `activemodel_reinclude_overrides.sake`: a module included a second time (through another module) pastes its functions
  again over a later module's override; Ruby keeps the override (the module is already an ancestor). ActiveModel includes
  ActiveSupport::Callbacks through Validations, Validations::Callbacks, Callbacks, SecurePassword, so this port never
  overrides an included module's function in another module; what must win is generated into the class.
- A mixin that uses `@field` or calls `new` cannot be included in another module ("`include ActiveModel::Validations` in
  ActiveModel::API: ... uses `@__errors`, but ActiveModel::API is not a class with field `__errors`"). Rails' modules
  include each other everywhere (API includes Validations includes Naming), so every field is reached through stub readers
  and writers (`def __errors(r) = raise(NotImplementedError)`, `set___errors`) that the class's field satisfies, and
  `build` (which calls `new`) is generated instead of being API's. Not a bug, but the shape every Rails concern needs.
- A user `==` is called for `x == nil`: `AttributeSet#==` (Ruby: `other.is_a?(AttributeSet) && ...`) was checked with nil
  from `raise ... if s == nil` and failed until it tested `other in AttributeSet` first, as Ruby's does.
- The Date/record `==` failure above (reached only from ActiveModel's interpolation values; no small repro reproduced it,
  and 23307e9a's Date#<=> change covers its cause).

## Friction (what I wrote first → the message → what I wrote instead)

1. `def MISSING_TRANSLATION = -(2**60)` in a mixin, called `Translation.MISSING_TRANSLATION` → "is a mixin function: it has
   no subject to dispatch on" (hint: mark it with module_function) → the constants moved after `module_function` (five
   modules). The hint was exactly right.
2. `def attributes=(r, h) = assign_attributes(r, h)` → "a setter method cannot be defined in an endless method definition"
   (Ruby's own rule) → a `def ... end`.
3. Validations' `@__errors ||= Errors.new(r)` in a module that API includes → the mixin-in-module error above → stub reader and
   writer. Ten fields' worth of `def __x(r) = raise(NotImplementedError)` / `def set___x(r, v) = ...`: the noisiest part of the port.
4. Serialization's stub `def attributes(r) = raise(NotImplementedError)` would have pasted over ActiveModel::Attributes' real
   `attributes` in a class that includes Serializers::JSON after Attributes (the order Rails apps write) → the stub is
   `__attributes_for_serialization`, and the generator writes `= attributes(r)`. Rule I ended with: a mixin's stub may only
   be for a name the generator always defines in the class.
5. `Hash.include?(@options, :with) ^ Hash.include?(@options, :without)` → "Bitwise.^: the operands are (true|false,
   true|false)" → `!=`.
6. `value == nil` with value a union holding a Date, a BigDecimal and a record → "date.sake:59: case/in: no `in` branch
   matches BigDecimal | Signup" deep inside date.sake → `(value in nil)` in five validators, then the record left out of the
   interpolation values (see above). The message pointed into date.sake, 15 hops from my line.
7. `p(m in Person ? Person.name(m) : nil)` → syntax error with the hint "`x in T` needs its own parentheses" → fixed at once.
8. `ActiveModel::SecurePassword.authenticate(record, digest, pw)` as a module function of a mixin the class includes → the
   class's `User.authenticate(u, pw)` became "given 2, expected 3": module functions after `module_function` are also the
   includer's names → `authenticate_digest`. A module's helpers and its includer's API share one namespace.
9. `attr_accessor` fields assigned by `build(Hash.of(name: "x", balance: 500, frozen_account: true))` all became
   `String | Integer | true | false`, and `String.strip(@name)` failed at level 2 → the callbacks test uses
   `Account.new(name: ..., balance: ...)` (Sake's keyword fields keep each field's type). An `attr_accessor` model is as
   untyped as Ruby's; an `attribute :x, :string` model is typed, which is the better Sake shape.
10. `p(ActiveModel::Errors.first(errs))` (Enum's first) printed fine but made the checker see an Array where an Error was
    expected in Error.message ("argument 1 must be ActiveModel::Error, but can be Array") → `Array.first(Errors.errors(errs))`.

What read well: the validators are Rails' code nearly line for line (LengthValidator's `CHECKS.each` with the shared
errors_options Hash, Numericality's parse_as_number chain, Clusivity's cover?/include? choice), and their messages and
`errors.details` match Rails' byte for byte because the options Hash keeps Rails' key order. ActiveSupport::Callbacks
took validators, validation callbacks and model callbacks without a change: the chain is data, and the generator only had
to translate class-body lines into its lines. The checker found real mistakes early: an unchecked `@attributes` in
EachValidator, `AttributeMutationTracker.new` with too few fields, a mixin calling a function no includer had. What read
badly: every model call carries its class (`Person.valid?(pe)`, `ActiveModel::Errors.full_messages(Person.errors(pe))`
for `pe.errors.full_messages`), and Ruby's single-name class/instance pairs (`model_name`, `attribute_names`) became two
names. The test files are about 1.25x Ruby's characters (attributes 1.46x; secure_password's .rb is longer only for its bcrypt fallback).
