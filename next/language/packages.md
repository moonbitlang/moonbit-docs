# Managing Projects with Packages

When developing projects at large scale, the project usually needs to be divided into smaller modular unit that depends on each other. 
More often, it involves using other people's work: most noticeably is the [core](https://github.com/moonbitlang/core), the standard library of MoonBit.

## Packages and modules

In MoonBit, the most important unit for code organization is a package, which consists of a number of source code files and a single `moon.pkg.json` configuration file.
A package can either be a `main` package, consisting a `main` function, or a package that serves as a library, identified by the [`is-main`](/toolchain/moon/package.md#is-main) field.

A project, corresponding to a module, consists of multiple packages and a single `moon.mod.json` configuration file.

A module is identified by the [`name`](/toolchain/moon/module.md#name) field, which usually consists to parts, seperated by `/`: `user-name/project-name`.
A package is identified by the relative path to the source root defined by the [`source`](/toolchain/moon/module.md#source-directory) field. The full identifier would be `user-name/project-name/path-to-pkg`.

When using things from another package, the dependency between modules should first be declared inside the `moon.mod.json` by the [`deps`](/toolchain/moon/module.md#deps) field.
The dependency between packages should then be declared in side the `moon.pkg.json` by the [`import`](/toolchain/moon/package.md#import) field.

(default-alias)=
The **default alias** of a package is the last part of the identifier split by `/`.
One can use `@pkg_alias` to access the imported entities, where `pkg_alias` is either the full identifier or the default alias.
A custom alias may also be defined with the [`import`](/toolchain/moon/package.md#import) field.

```{literalinclude} /sources/language/src/packages/pkgB/moon.pkg.json
:language: json
:caption: pkgB/moon.pkg.json
```

```{literalinclude} /sources/language/src/packages/pkgB/top.mbt
:language: moonbit
:caption: pkgB/top.mbt
```

### Internal Packages

You can define internal packages that are only available for certain packages.

Code in `a/b/c/internal/x/y/z` are only available to packages `a/b/c` and `a/b/c/**`.

## Access Control

MoonBit features a comprehensive access control system that governs which parts of your code are accessible from other packages. 
This system helps maintain encapsulation, information hiding, and clear API boundaries. 
The visibility modifiers apply to functions, variables, types, and traits, allowing fine-grained control over how your code can be used by others.

### Functions

By default, all function definitions and variable bindings are _invisible_ to other packages.
You can use the `pub` modifier before toplevel `let`/`fn` to make them public.

### Types

There are four different kinds of visibility for types in MoonBit:

- private type, declared with `priv`, completely invisible to the outside world
- abstract type, which is the default visibility for types. Only the name of an abstract type is visible outside, the internal representation of the type is hidden
- readonly types, declared with `pub`. The internal representation of readonly types are visible outside,
but users can only read the values of these types from outside, construction and mutation are not allowed
- fully public types, declared with `pub(all)`. The outside world can freely construct, modify and read values of these types

In addition to the visibility of the type itself, the fields of a public `struct` can be annotated with `priv`,
which will hide the field from the outside world completely.
Note that `struct`s with private fields cannot be constructed directly outside,
but you can update the public fields using the functional struct update syntax.

Readonly types is a very useful feature, inspired by [private types](https://ocaml.org/manual/5.3/privatetypes.html) in OCaml. In short, values of `pub` types can be destructed by pattern matching and the dot syntax, but cannot be constructed or mutated in other packages. Note that there is no restriction within the same package where `pub` types are defined.

<!-- MANUAL CHECK -->

```moonbit
// Package A
pub struct RO {
  field: Int
}
test {
  let r = { field: 4 }       // OK
  let r = { ..r, field: 8 }  // OK
}

// Package B
fn println(r : RO) -> Unit {
  println("{ field: ")
  println(r.field)  // OK
  println(" }")
}
test {
  let r : RO = { field: 4 }  // ERROR: Cannot create values of the public read-only type RO!
  let r = { ..r, field: 8 }  // ERROR: Cannot mutate a public read-only field!
}
```

Access control in MoonBit adheres to the principle that a `pub` type, function, or variable cannot be defined in terms of a private type. This is because the private type may not be accessible everywhere that the `pub` entity is used. MoonBit incorporates sanity checks to prevent the occurrence of use cases that violate this principle.

<!-- MANUAL CHECK -->
```moonbit
pub(all) type T1
pub(all) type T2
priv type T3

pub(all) struct S {
  x: T1  // OK
  y: T2  // OK
  z: T3  // ERROR: public field has private type `T3`!
}

// ERROR: public function has private parameter type `T3`!
pub fn f1(_x: T3) -> T1 { ... }
// ERROR: public function has private return type `T3`!
pub fn f2(_x: T1) -> T3 { ... }
// OK
pub fn f3(_x: T1) -> T1 { ... }

pub let a: T3 = { ... } // ERROR: public variable has private type `T3`!
```

### Traits

There are four visibility for traits, just like `struct` and `enum`: private, abstract, readonly and fully public.
- Private traits are declared with `priv trait`, and they are completely invisible from outside.
- Abstract trait is the default visibility. Only the name of the trait is visible from outside, and the methods in the trait are not exposed.
- Readonly traits are declared with `pub trait`, their methods can be invoked from outside, but only the current package can add new implementation for readonly traits.
- Fully public traits are declared with `pub(open) trait`, they are open to new implementations outside current package, and their methods can be freely used.

Abstract and readonly traits are sealed, because only the package defining the trait can implement them.
Implementing a sealed (abstract or readonly) trait outside its package result in compiler error.

#### Trait Implementations

Implementations have independent visibility, just like functions. The type will not be considered having fulfillled the trait outside current package unless the implementation is `pub`.

To make the trait system coherent (i.e. there is a globally unique implementation for every `Type: Trait` pair),
and prevent third-party packages from modifying behavior of existing programs by accident,
MoonBit employs the following restrictions on who can define methods/implement traits for types:

- _only the package that defines a type can define methods for it_. So one cannot define new methods or override old methods for builtin and foreign types.
- _only the package of the type or the package of the trait can define an implementation_.
  For example, only `@pkg1` and `@pkg2` are allowed to write `impl @pkg1.Trait for @pkg2.Type`.

The second rule above allows one to add new functionality to a foreign type by defining a new trait and implementing it.
This makes MoonBit's trait & method system flexible while enjoying good coherence property.

```{warning}
Currently, an empty trait is implemented automatically.
```

Here's an example of abstract trait:

<!-- MANUAL CHECK -->
```{code-block} moonbit
:class: top-level
trait Number {
 op_add(Self, Self) -> Self
 op_sub(Self, Self) -> Self
}

fn[N : Number] add(x : N, y: N) -> N {
  Number::op_add(x, y)
}

fn[N : Number] sub(x : N, y: N) -> N {
  Number::op_sub(x, y)
}

impl Number for Int with op_add(x, y) { x + y }
impl Number for Int with op_sub(x, y) { x - y }

impl Number for Double with op_add(x, y) { x + y }
impl Number for Double with op_sub(x, y) { x - y }
```

From outside this package, users can only see the following:

```{code-block} moonbit
trait Number

fn[N : Number] op_add(x : N, y : N) -> N
fn[N : Number] op_sub(x : N, y : N) -> N

impl Number for Int
impl Number for Double
```

The author of `Number` can make use of the fact that only `Int` and `Double` can ever implement `Number`,
because new implementations are not allowed outside.

## Virtual Packages

```{warning}
Virtual package is an experimental feature. There may be bugs and undefined behaviors.
```

You can define virtual packages, which serves as an interface. They can be replaced by specific implementations at build time. Currently virtual packages can only contain plain functions.

Virtual packages can be useful when swapping different implementations while keeping the code untouched.

### Defining a virtual package

You need to declare it to be a virtual package and define its interface in a MoonBit interface file.

Within `moon.pkg.json`, you will need to add field [`virtual`](/toolchain/moon/package.md#declarations) :

```{literalinclude} /sources/language/src/packages/virtual/moon.pkg.json
:language: json
```

The `has-default` indicates whether the virtual package has a default implementation.

Within the package, you will need to add an interface file `package-name.mbti` where the `package-name` is the same as [the default alias](#default-alias):

```{literalinclude} /sources/language/src/packages/virtual/virtual.mbti
:language: moonbit
:caption: /src/packages/virtual/virtual.mbti
```

The first line of the interface file need to be `package "full-package-name"`. Then comes the declarations.
The `pub` keyword for [access control](#access-control) and the function parameter names should be omitted.

```{hint}
If you are uncertain about how to define the interface, you can create a normal package, define the functions you need using [TODO syntax](/language/fundamentals.md#todo-syntax), and use `moon info` to help you generate the interface.
```

### Implementing a virtual package

A virtual package can have a default implementation. By defining [`virtual.has-default`](/toolchain/moon/package.md#declarations) as `true`, you can implement the code as usual within the same package.

```{literalinclude} /sources/language/src/packages/virtual/top.mbt
:language: moonbit
:caption: /src/packages/virtual/top.mbt
```

A virtual package can also be implemented by a third party. By defining [`implements`](/toolchain/moon/package.md#implementations) as the target package's full name, the compiler can warn you about the missing implementations or the mismatched implementations.

```{literalinclude} /sources/language/src/packages/implement/moon.pkg.json
:language: json
```

```{literalinclude} /sources/language/src/packages/implement/top.mbt
:language: moonbit
:caption: /src/packages/implement/top.mbt
```

### Using a virtual package

To use a virtual package, it's the same as other packages: define [`import`](/toolchain/moon/package.md#import) field in the package where you want to use it.

### Overriding a virtual package

If a virtual package has a default implementation and that is your choice, there's no extra configurations.

Otherwise, you may define the [`overrides`](/toolchain/moon/package.md#overriding-implementations) field by providing an array of implementations that you would like to use.

```{literalinclude} /sources/language/src/packages/use_implement/moon.pkg.json
:language: json
:caption: /src/packages/use_implement/moon.pkg.json
```

You should reference the virtual package when using the entities.

```{literalinclude} /sources/language/src/packages/use_implement/top.mbt
:language: moonbit
:caption: /src/packages/use_implement/top.mbt
```