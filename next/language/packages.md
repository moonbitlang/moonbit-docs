# Managing Projects with Packages

When developing projects at large scale, the project usually needs to be divided into smaller modular unit that depends on each other. 
More often, it involves using other people's work: most noticeably is the [core](https://github.com/moonbitlang/core), the standard library of MoonBit.

## Packages and modules

In MoonBit, the most important unit for code organization is a package, which consists of a number of source code files and a single `moon.pkg.json` configuration file.
A package can either be a `main` package, consisting a `main` function, or a package that serves as a library. 

A project, corresponding to a module, consists of multiple packages and a single `moon.mod.json` configuration file.

When using things from another package, the dependency between modules should first be declared inside the `moon.mod.json`.
The dependency between packages should then be declared inside the `moon.pkg.json`.
Then it is possible to use `@pkg` to access the imported entities, where `pkg` is the last part of the imported package's path or the declared alias in `moon.pkg.json`:

```{literalinclude} /sources/language/src/packages/pkgB/moon.pkg.json
:language: json
:caption: pkgB/moon.pkg.json
```

```{literalinclude} /sources/language/src/packages/pkgB/top.mbt
:language: moonbit
:caption: pkgB/top.mbt
```

## Access Control

By default, all function definitions and variable bindings are _invisible_ to other packages.
You can use the `pub` modifier before toplevel `let`/`fn` to make them public.

There are four different kinds of visibility for types in MoonBit:

- private type, declared with `priv`, completely invisible to the outside world
- abstract type, which is the default visibility for types. Only the name of an abstract type is visible outside, the internal representation of the type is hidden
- readonly types, declared with `pub(readonly)`. The internal representation of readonly types are visible outside,
but users can only read the values of these types from outside, construction and mutation are not allowed
- fully public types, declared with `pub(all)`. The outside world can freely construct, modify and read values of these types

Currently, the semantic of `pub` is `pub(all)`. But in the future, the meaning of `pub` will be ported to `pub(readonly)`.
In addition to the visibility of the type itself, the fields of a public `struct` can be annotated with `priv`,
which will hide the field from the outside world completely.
Note that `struct`s with private fields cannot be constructed directly outside,
but you can update the public fields using the functional struct update syntax.

Readonly types is a very useful feature, inspired by [private types](https://v2.ocaml.org/manual/privatetypes.html) in OCaml. In short, values of `pub(readonly)` types can be destructed by pattern matching and the dot syntax, but cannot be constructed or mutated in other packages. Note that there is no restriction within the same package where `pub(readonly)` types are defined.

<!-- MANUAL CHECK -->

```moonbit
// Package A
pub(readonly) struct RO {
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

## Access control of methods and trait implementations

To make the trait system coherent (i.e. there is a globally unique implementation for every `Type: Trait` pair),
and prevent third-party packages from modifying behavior of existing programs by accident,
MoonBit employs the following restrictions on who can define methods/implement traits for types:

- _only the package that defines a type can define methods for it_. So one cannot define new methods or override old methods for builtin and foreign types.
- _only the package of the type or the package of the trait can define an implementation_.
  For example, only `@pkg1` and `@pkg2` are allowed to write `impl @pkg1.Trait for @pkg2.Type`.

The second rule above allows one to add new functionality to a foreign type by defining a new trait and implementing it.
This makes MoonBit's trait & method system flexible while enjoying good coherence property.

## Visibility of traits and sealed traits
There are four visibility for traits, just like `struct` and `enum`: private, abstract, readonly and fully public.
Private traits are declared with `priv trait`, and they are completely invisible from outside.
Abstract trait is the default visibility. Only the name of the trait is visible from outside, and the methods in the trait are not exposed.
Readonly traits are declared with `pub(readonly) trait`, their methods can be involked from outside, but only the current package can add new implementation for readonly traits.
Finally, fully public traits are declared with `pub(open) trait`, they are open to new implementations outside current package, and their methods can be freely used.
Currently, `pub trait` defaults to `pub(open) trait`. But in the future, the semantic of `pub trait` will be ported to `pub(readonly)`.

Abstract and readonly traits are sealed, because only the package defining the trait can implement them.
Implementing a sealed (abstract or readonly) trait outside its package result in compiler error.
If you are the owner of a sealed trait, and you want to make some implementation available to users of your package,
make sure there is at least one declaration of the form `impl Trait for Type with ...` in your package.
Implementations with only regular method and default implementations will not be available outside.

Here's an example of abstract trait:

<!-- MANUAL CHECK -->
```moonbit
trait Number {
 op_add(Self, Self) -> Self
 op_sub(Self, Self) -> Self
}

fn add[N : Number](x : N, y: N) -> N {
  Number::op_add(x, y)
}

fn sub[N : Number](x : N, y: N) -> N {
  Number::op_sub(x, y)
}

impl Number for Int with op_add(x, y) { x + y }
impl Number for Int with op_sub(x, y) { x - y }

impl Number for Double with op_add(x, y) { x + y }
impl Number for Double with op_sub(x, y) { x - y }
```

From outside this package, users can only see the following:

```moonbit
trait Number

fn op_add[N : Number](x : N, y : N) -> N
fn op_sub[N : Number](x : N, y : N) -> N

impl Number for Int
impl Number for Double
```

The author of `Number` can make use of the fact that only `Int` and `Double` can ever implement `Number`,
because new implementations are not allowed outside.
