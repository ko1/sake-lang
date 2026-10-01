# Prior art for operation-side union calls: `(A|B).op(x)`

Date: 2026-10-01. The question: has any language put a **set of types on the operation** at a call site, as in Sake's proposed
`(String|Array).length(obj)` and `(Leaf|Node).get_weight(t)`? The intended semantics are:

* at run time, `obj` must be one of the listed types (otherwise error); the call goes to that type's `op`;
* statically, every listed type must have `op`; the result type is the union of the per-type result types;
* the union belongs to this one call, not to the value or variable.

Method: web search plus primary docs. Where a toolchain was installed locally (Go 1.26.0, rustc, OCaml), the claim was
also checked by compiling a small program. Those checks are marked **[run]**. Everything else comes from the cited docs,
and claims I inferred from a doc rather than ran are marked **[inferred]**.

## Verdict

**I found no language or paper with a call form that lists a union of types on the operation and dispatches to each
listed type's own implementation.** Each piece of the proposal exists somewhere, but they are not combined in that
shape:

* **Static rule ("every member has op; result is the union").** Pony, TypeScript, Flow, and Crystal use this rule for
  method calls on union-typed *values*. Go generics use it for built-in operations (`len`) on type-set constraints.
  Castagna's "union elimination" is the formal version.
* **Run-time check plus per-type dispatch over a closed, written-out list.** Crystal's `x.as(A | B).m` does this, but
  the list is attached to the value. Zig's `inline .a, .b => |p| p.op()` comes closer: it is written at the use site
  and instantiates the body once per listed variant. It is still a `switch` on a tagged-union value, not a call form.
* **Naming the operation's owner at the call site.** Rust `<T as Trait>::f`, C++ `x.A::f()`, Raku `$o.Parent::m`,
  Haskell `f @T`, Julia `invoke`, and Ruby `bind_call` all exist, but each names exactly **one** type or
  implementation. Julia `invoke` does accept a `Union` in its signature, but then it picks **one** method that covers
  the whole union. It does not split the call per member.
* **Shared field across record types.** Go explicitly considered and refused `p.X` over `Point | Rect | Elli`
  (golang/go#48522). Rust and OCaml or-patterns reject bindings of different types **[run]**. Zig `inline else`
  accepts it.

The closest precedents, in order:

1. **Zig `inline` switch prongs.** Use-site list, per-type instantiation, exhaustiveness checked, and shared fields
   work (`slice.len` across different struct types). It differs from the proposal in three ways: it only works on a
   tagged-union value, it is a statement and not an operation name, and the results must resolve to one peer type
   instead of a union.
2. **Crystal `x.as(A | B).m`.** Same run-time check and same per-type dispatch, and the result is a union. But the
   union is attached to the value expression.
3. **Go generics `func F[T A | B](x T)` with `len(x)`.** The type list is attached to an operation (a function), and
   an operation is legal if it is "valid for any type permitted by the constraint". But it is a definition-site
   constraint, resolved statically. The field-access part (`x.Weight`) is rejected **[run]**.
4. **Elixir protocols, `Proto.op(x)`.** The operation-side qualifier names a set of implementing types, and the type
   checker treats it as the union `Proto.t()`. But the set is open and is declared by `defimpl`, not listed at the
   call site.

So `(A|B).op(x)` reads as a user-written, statically checked **polymorphic inline cache**: a per-call-site set of
receiver classes (Hölzle, Chambers & Ungar 1991), which until now was only a VM-internal artifact. That is an
analogy, not a precedent.

## Summary table

"Side" says where the type set is written: **op** means on the operation or call, **val** means on a value or
expression, **def** means on a function or method definition.

| # | Language / work | Syntax | Side | Run-time check | Static rule | Result type | Per-type dispatch? | Closeness |
|---|---|---|---|---|---|---|---|---|
| 1 | Zig inline prongs | `switch (u) { inline .a, .b => \|p\| p.len, ... }` | use-site (switch) | tag switch, exhaustive | body checked once per listed variant | peer-resolved single type | yes (comptime instantiation) | **closest in shape** |
| 2 | Crystal | `x.as(A \| B).m` | val | yes, raises on mismatch | all members must respond to `m` | union | yes (by runtime type id) | **closest in semantics** |
| 3 | Go generics | `func L[T string \| []int](x T) int { return len(x) }` | def (constraint) | none (static instantiation) | op valid for every type in the set | declared | no (monomorphic or dictionary) | op-ish, static only |
| 4 | Go #48522 | `func GetX[P Point\|Rect\|Elli](p P) int { return p.X }` | def | none | **rejected** today | n/a | n/a | the field case, refused |
| 5 | Go type switch | `case string, []int:` | val | yes | binding stays `any` | n/a | no | val-side, loses type **[run]** |
| 6 | Pony | `let x: (A \| B) = ...; x.m()` | val | n/a (static) | every member must have `m` | union | yes | val-side |
| 7 | TypeScript / Flow | `(x as A \| B).m()` | val | **none** (`as` is unchecked) | property must exist on every member; union-of-function call intersects parameters (TS 3.3) | union | yes (JS dynamic) | val-side, unchecked cast |
| 8 | Scala 3 | `(x: A \| B).hello` | val | n/a | members of the **join** only (structural `hello` rejected) | join member type | yes (virtual) | weaker static rule |
| 9 | Ceylon | `A\|B` | val | n/a | members of the common supertype | — | virtual | weaker static rule |
| 10 | Common Lisp | `(the (or a b) x)` | val | undefined if wrong (SBCL checks at safety>0) | declaration only | — | generic function dispatches normally | val-side |
| 11 | CL `etypecase` / Modula-3 `TYPECASE` | `((or a b) ...)` / `T1, T2 => S` | use-site (case) | yes | M3: comma list is shorthand for repeating the arm per type, but **no binding allowed** | — | M3: conceptually yes | precursor of Zig |
| 12 | C++ `std::visit` + generic lambda | `std::visit([](auto& v){ return v.size(); }, var)` | val (`variant<A,B>`) | variant index | lambda instantiated per alternative | **must be identical** across alternatives | yes | val-side, Zig-like |
| 13 | Rust / OCaml or-patterns | `T::Leaf(x) \| T::Node(x) => x.weight` | use-site | — | **rejected**: binding must have one type **[run]** | — | — | refused |
| 14 | Julia `invoke` | `invoke(f, Tuple{Union{A,B}}, x)` | op | `x` must be in the union | — | — | **no**: one method covering the whole union **[inferred]** | op-side but not split |
| 15 | Julia / Dylan / Cecil / Python singledispatch | `f(x::Union{A,B})`, `x :: type-union(<a>,<b>)` | def | dispatch | — | — | the union is one specializer | def-side |
| 16 | Rust UFCS, C++ qualified, Raku, Ruby, Haskell `@T`, Lean `@f inst` | `<T as Tr>::f(x)`, `x.A::f()`, `$o.Parent::m`, `String.instance_method(:length).bind_call(s)`, `length @[]` | op | — | — | — | single type only | op-side, singleton |
| 17 | Elixir protocols | `String.Chars.to_string(x)` | op (protocol name) | protocol dispatch, `Protocol.UndefinedError` | type is union `String.Chars.t()` of the impls | — | yes | op-side, open set not listed |
| 18 | Clojure protocols / multimethods | `(count x)`, `defmulti` | op (open) | yes | none | — | yes | op-side, open |
| 19 | Haskell DuplicateRecordFields / HasField | `getField @"weight" t` | val (constraint) | — | one record type per resolution | — | no | field case, single type |
| 20 | Castagna et al., union elimination / occurrence typing | typing rule | theory | — | type the expression once per union member, join the results | union | — | the formal static rule |
| 21 | Polymorphic inline caches (Hölzle et al. 1991) | VM-internal | op (per site, inferred) | class test chain | none | — | yes | implementation analogue |

## Details

### Value-side analogues (confirming the known ones)

**Crystal `x.as(A | B)`.** `as` is a checked cast: "if `a` wasn't an `Int32`, an exception is raised". With a union
argument, `b = a.as(Int32 | Float64)` gives `b :: Int32 | Float64`. A later call `b.m` compiles only if every member
has `m`; Crystal then dispatches on the runtime type id, and the call's type is the union of the results. In behavior
this matches the proposal exactly, but the union belongs to the expression. A second call `b.n` reuses the same
narrowed value, which is the reverse of Sake's "type on the operation".
<https://crystal-lang.org/reference/latest/syntax_and_semantics/as.html>

**TypeScript `(x as A | B).m()`.** `as` is unchecked and has no run-time effect. Statically, "TypeScript will only
allow an operation if it is valid for *every* member of the union"; for example `x.slice(0,3)` on `number[] | string`
is allowed. Since TS 3.3, calling a union of function types intersects the parameters. This has caveats: at most one
member may be generic or overloaded, so `map` on `number[] | string[]` is not callable. The result is the union. Flow
behaves the same way.
<https://www.typescriptlang.org/docs/handbook/2/everyday-types.html>,
<https://www.typescriptlang.org/docs/handbook/release-notes/typescript-3-3.html>

**Common Lisp `(the (or a b) x)`.** CLHS: "The consequences are undefined if the values yielded by the form are not of
the type specified". It is a declaration, not a dispatch construct. SBCL turns it into a check at default safety, but
the standard does not require that. The dispatch of the following generic-function call does not change.
<https://www.lispworks.com/documentation/HyperSpec/Body/s_the.htm>

**Pony.** A union type is closed-world; "you can only call methods on the union that are specified in all of the
union's member types". This is the same static rule as Sake's, applied to a value's type.
<https://tutorial.ponylang.io/types/type-expressions.html>

**Scala 3 and Ceylon.** These use a weaker rule. The members of `A | B` are the members of its **join** (common
supertype). Two unrelated traits that each define `hello` give "value `hello` is not a member of A | B". Ceylon
works the same way: "If X and Y are both subtypes of a third type Z, then X|Y inherits all members of Z". This is
useful contrast: Sake's rule is structural per member, as in Pony, TypeScript, and Crystal, not nominal via a join.
<https://docs.scala-lang.org/scala3/reference/new-types/union-types-spec.html>,
<https://ceylon-lang.org/documentation/1.0/spec/html/typesystem.html>

### Use-site type lists (closest shape)

**Zig `inline` switch prongs.** A prong marked `inline` is generated "for each possible value it could have, making the
captured value comptime". On a tagged union, the payload capture's type is known at compile time and differs per
instantiation. The official example accesses a shared field across *different* payload types:

```zig
const AnySlice = union(enum) { a: SliceTypeA, b: SliceTypeB, c: []const u8, d: []AnySlice };
fn withSwitch(any: AnySlice) usize {
    return switch (any) { inline else => |slice| slice.len };  // exhaustiveness checked
}
```

`inline .a, .b => |s| s.len` lists a subset explicitly. That is the nearest thing to `(A|B).len(x)` I found:

* the type list is written at the use site;
* each listed type type-checks the operation separately;
* the dispatch is by the runtime tag;
* the shared-field case works.

It differs from the proposal in three ways:

* it needs a tagged-union value, so you cannot apply it to an arbitrary value of an open type;
* it is a `switch` statement, not a call;
* the prong results must peer-resolve to one type, because Zig has no union result types.

<https://ziglang.org/documentation/0.14.0/#Inline-Switch-Prongs>

**Modula-3 `TYPECASE`.** "If (v) is absent, then Ti can be a list of type expressions separated by commas, as
shorthand for a list in which the rest of the branch is repeated for each type expression." Conceptually this is
per-type replication of one arm, which is the idea behind Zig's inline prongs. But because a multi-type arm cannot
bind a variable, the body cannot call a type-specific operation on the value.
<https://softwarepreservation.computerhistory.org/modula3/doc/SRC-RR-52.pdf>

**Go type switch, `case string, []int:`.** The spec says that in a multi-type case the variable keeps the switch
operand's interface type. Checked **[run]**: `len(y)` in such a case fails with
`invalid argument: y (variable of interface type any) for built-in len`. This is the opposite design choice to Zig's.

**C++ `std::visit` with a generic lambda.** The lambda is instantiated per alternative of `variant<A,B>`, so each
alternative must support the operation. But "the results ... [must not] have different types or value categories for
different indices", so there is no union result.
<https://en.cppreference.com/w/cpp/utility/variant/visit2>

**Rust and OCaml or-patterns.** Both reject one binding with different types across alternatives **[run]**:

* Rust: `error[E0308]` and "in the same arm, a binding must have the same type in all alternatives".
* OCaml: "The variable x on the left-hand side of this or-pattern has type leaf but on the right-hand side it has type
  node".

The idiom `(Leaf|Node).get_weight(t)` therefore has no direct spelling in either language. The usual workaround is a
macro or a crate (`enum_dispatch`).

### Operation-side qualification (singleton only)

* **Rust** `<T as Trait>::f(x)`; **C++** `x.A::f()`, which is non-virtual; **Raku** `$test.Parent::frob`
  (<https://docs.raku.org/language/objects>); **Ruby** `String.instance_method(:length).bind_call(s)`; **Haskell**
  `length @[] xs` (TypeApplications); **Lean** `@f inst x`; **Scala** explicit `using` arguments. Each selects
  **one** implementation and does no dispatch. Sake's single-type form `String.length(s)` sits in this family. None of
  these languages allows a union at that position.
* **Julia `invoke(f, argtypes, args...)`.** It invokes "a method ... matching the specified types `argtypes`", and the
  args "must conform with the specified types". The tuple type may contain a `Union`. Lookup then works as for a call
  whose declared argument type is the union itself, so it picks the single most specific method whose signature covers
  all of `Union{A,B}`, for example `f(::Any)` or `f(::Union{A,B})`. It does **not** route a `String` to `f(::String)`.
  This is **[inferred]** from the docstring and `which`'s note that for abstract types it "returns the method that
  would be called by `invoke`". Julia was not available to run it. So Julia has the syntax for an operation-side union,
  with the opposite semantics: it restricts the call to one method instead of dispatching among several.
  <https://github.com/JuliaLang/julia/blob/master/base/docs/basedocs.jl>
* **CLOS.** `find-method` takes a list of specializers (classes or `eql`), one method. There are no union
  specializers, and method qualifiers (`:before` and so on) choose a combination role, not a type set.
* **Elixir protocols.** `String.Chars.to_string(x)` qualifies the operation with a protocol. The new type system
  treats the protocol as a type: "The union of all types that implement String.Chars is automatically filled in by the
  Elixir compiler and denoted by String.Chars.t()". This is the closest **operation-side** form in a shipping
  language. However, the set is open (it grows with `defimpl`) and is not written at the call site. Clojure protocols
  and multimethods are similar, with no static set.
  <https://hexdocs.pm/elixir/gradual-set-theoretic-types.html>, <https://arxiv.org/pdf/2306.06391>

### Definition-side unions

* Julia `f(x::Union{A,B})`, Dylan `define method red? (x :: type-union(<frog>, <broccoli>))`
  (<https://opendylan.org/books/drm/Union_Types>), Cecil `|` types, and Python `@singledispatch` registration with
  `int | str` (3.11+).
* Nim typeclasses `proc f(x: int | string)` are instantiated per concrete static type.

In each of these the union is the **specializer of one method**, and the body must work for both types (for example
by further dispatch). Sake's form instead routes to *different* existing definitions.

**Go generics** are the strongest definition-side match:

* `func L[T string | []int](x T) int { return len(x) }` compiles, and so does `L("abc")`. The rule (Go blog,
  "Goodbye core types", 2025) is "an operation involving operands of generic type should be valid if it is valid for
  any type permitted by the respective type constraint". That is Sake's static rule, applied to built-in operations.
* Field access is refused. Checked **[run]** on go1.26.0: `t.Weight undefined (type T has no field or method Weight)`
  for `T Leaf | Node`. Proposal **golang/go#48522** ("permit referring to a field shared by all elements of a type
  set", example `GetX[P Point|Rect|Elli]`) has 95 comments. Its GitHub state is closed, and later commenters are
  asking for it to be reopened. The core-types blog post calls it "a natural and useful consequence of the ordinary
  rules" once core types are gone.
* Go's reason for hesitating is relevant to Sake: "how it interacts with methods since one cannot have fields and
  methods of a same name".

<https://go.dev/blog/coretypes>, <https://github.com/golang/go/issues/48522>

### Shared fields across variants

* **Haskell.** A selector over several constructors of one type is partial and fails at run time with "No match in
  record selector". DuplicateRecordFields requires an unambiguous selector, or disambiguation by a type signature,
  meaning one type. `HasField "weight" r Int` resolves to one record type per use.
  <https://ghc.gitlab.haskell.org/ghc/doc/users_guide/exts/duplicate_record_fields.html>
* **OCaml.** Records use type-directed disambiguation to one type. Object types with row polymorphism
  (`< weight : int; .. >`) accept any object with the method, which is open and has no listed set.
* **Elm extensible records `{ r | weight : Int }`, and row polymorphism in general.** These are structural and open,
  with no run-time dispatch (one field-offset lookup).
* **TypeScript discriminated unions.** Accessing a property common to all members is allowed without narrowing; the
  result is the union of the property types.
* **Zig.** `inline else => |p| p.weight` works (see above).

### Academic

* **Castagna, Petrucciani, Nguyen, "On Type-Cases, Union Elimination, and Occurrence Typing", POPL 2022.** The union
  elimination rule types an expression by splitting a subterm's union type and checking each case separately. That is
  the formal version of "check `op` for each listed type, then union the results".
  <https://www.irif.fr/~gc/papers/popl22.pdf>
* **Castagna, "Programming with Union, Intersection, and Negation Types" (2022).** Overloaded functions with intersection
  types plus type-cases. Here the *function* carries the per-type cases; for example `length : (String→Int) ∧
  (Array→Int)` applied to `String|Array` gives `Int`.
  <https://www.irif.fr/~gc/papers/set-theoretic-types-2022.pdf>
* **Castagna, Ghelli, Longo, λ& (1992).** Overloaded functions as sets of branches chosen by the argument's run-time
  type. This is the theory of dispatching among listed implementations.
* **Typed Racket occurrence typing.** Narrows value-side unions after predicates; the value-side counterpart.
* **Hölzle, Chambers, Ungar, "Optimizing Dynamically-Typed Object-Oriented Languages With Polymorphic Inline Caches",
  ECOOP 1991.** A per-call-site set of receiver classes with a type test and dispatch chain. A `(A|B).op(x)` site is
  a source-level, statically verified PIC. This is an analogy, not a language feature.

## Implications for Sake (observations, not decisions)

* **The static rule has precedent.** "All listed types must have `op`; the result is the union" is the Pony,
  TypeScript, and Crystal rule. Scala and Ceylon use a stricter join-based rule, which would reject `(String|Array).length`
  because the two types share no `length`-declaring supertype. Sake's structural choice follows the former group.
* **Writing the set at the call is the new part.** Zig gets closest, but needs a tagged-union value. Elixir protocols
  name a set on the operation, but the set is open and not written at the call site. I found no precedent for writing a
  closed union on a single call and checking it at run time.
* **The field case is the contested part.** Go has kept it open for years, and its stated worry is name collisions
  between fields and methods. Rust and OCaml do not allow it. Zig allows it.
* **Two semantics are possible for an operation-side union.** Julia `invoke` with a `Union` shows one: pick the
  implementation that covers the whole union. Sake's proposal is the other: route to the implementation for the
  value's member type. The Sake docs should say which one Sake uses, because a reader coming from Julia would expect
  the first.
