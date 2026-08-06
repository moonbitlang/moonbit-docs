# Method and Trait

## Method system

MoonBit supports methods in a different way from traditional object-oriented languages. A method in MoonBit is just a toplevel function associated with a type constructor.
To define a method, prepend `SelfTypeName::` in front of the function name, such as `fn SelfTypeName::method_name(...)`, and the method belongs to `SelfTypeName`.
Within the signature of the method declaration, you can use `Self` to refer to `SelfTypeName`.

#### WARNING
Currently, there is a shorthand syntax for defining methods.
When the name of the first parameter is `self`, a function declaration will be considered a method for the type of `self`.
This syntax may be deprecated in the future, and we do not recommend using it in new code.

```moonbit
fn method_name(self : SelfType) -> Unit { ... }
```

```moonbit
enum List[X] {
  Nil
  Cons(X, List[X])
}

///|
fn[X] List::length(xs : List[X]) -> Int {
  ...
}
```

To call a method, you can either invoke using qualified syntax `T::method_name(..)`, or using dot syntax where the first argument is the type of `T`:

```moonbit
let l : List[Int] = Nil
println(l.length())
println(List::length(l))
```

When the first parameter of a method is also the type it belongs to, methods can be called using dot syntax `x.method(...)`. MoonBit automatically finds the correct method based on the type of `x`, there is no need to write the type name and even the package name of the method:

```moonbit
pub(all) enum List[X] {
  Nil
  Cons(X, List[X])
}

pub fn[X] List::concat(list : List[List[X]]) -> List[X] {
  ...
}
```

```moonbit
// assume `xs` is a list of lists, all the following two lines are equivalent
let _ = xs.concat()
let _ = @list.List::concat(xs)
```

Unlike regular functions, methods defined using the `TypeName::method_name` syntax support overloading:
different types can define methods of the same name, because each method lives in a different name space:

```moonbit
struct T1 {
  x1 : Int
}

fn T1::default() -> T1 {
  { x1: 0 }
}

struct T2 {
  x2 : Int
}

fn T2::default() -> T2 {
  { x2: 0 }
}

test {
  let t1 = T1::default()
  let t2 = T2::default()

}
```

### Local method

To ensure single source of truth in method resolution and avoid ambiguity,
[methods can only be defined in the same package as its type](https://docs.moonbitlang.com/en/latest/language/packages.html#trait-implementations).
However, there is one exception to this rule: MoonBit allows defining *private* methods for foreign types locally.
These local methods can override methods from the type's own package (MoonBit will emit a warning in this case),
and provide extension/complementary to upstream API:

```moonbit
fn Int::my_int_method(self : Int) -> Int {
  self * self + self
}

test {
  assert_eq((6).my_int_method(), 42)
}
```

### Alias methods as functions

MoonBit allows calling methods with alternative names via alias.

The method alias will create a method with the corresponding name.
You can also choose to create a function with the corresponding name.
The visibility can also be controlled.

```moonbit
#alias(m)
#alias(n, visibility="priv")
#as_free_fn(m)
#as_free_fn(n, visibility="pub")
fn List::f() -> Bool {
  true
}
test {
  assert_eq(List::f(), List::m())
  assert_eq(List::m(), m())
}
```

## Operator Overloading

MoonBit supports overloading infix operators of builtin operators via several builtin traits. For example:

```moonbit
struct T {
  x : Int
}

impl Add for T with add(self : T, other : T) -> T {
  { x: self.x + other.x }
}

test {
  let a = T::{ x: 0 }
  let b = T::{ x: 2 }
  assert_eq((a + b).x, 2)
}
```

Other operators are overloaded via methods with annotations, for example `_[_]` and `_[_]=_`:

```moonbit
struct Coord {
  mut x : Int
  mut y : Int
}

#alias("_[_]")
fn Coord::get(coord : Self, key : String) -> Int {
  match key {
    "x" => coord.x
    "y" => coord.y
  }
}

#alias("_[_]=_")
fn Coord::set(coord : Self, key : String, val : Int) -> Unit {
  match key {
    "x" => coord.x = val
    "y" => coord.y = val
  }
}
```

```moonbit
fn main {
  let c = Coord::{ x: 1, y: 2 }
  println("{x: \{c.x}, y: \{c.y}}")
  println(c["y"])
  c["x"] = 23
  println("{x: \{c.x}, y: \{c.y}}")
  println(c["x"])
}
```

```none
{x: 1, y: 2}
2
{x: 23, y: 2}
23
```

Currently, the following operators can be overloaded:

| Operator Name         | overloading mechanism   |
|-----------------------|-------------------------|
| `+`                   | trait `Add`             |
| `-`                   | trait `Sub`             |
| `*`                   | trait `Mul`             |
| `/`                   | trait `Div`             |
| `%`                   | trait `Mod`             |
| `==`                  | trait `Eq`              |
| `<<`                  | trait `Shl`             |
| `>>`                  | trait `Shr`             |
| `-` (unary)           | trait `Neg`             |
| `_[_]` (get item)     | method + alias `_[_]`   |
| `_[_] = _` (set item) | method + alias `_[_]=_` |
| `_[_:_]` (view)       | method + alias `_[_:_]` |
| `&`                   | trait `BitAnd`          |
| `|`                   | trait `BitOr`           |
| `^`                   | trait `BitXOr`          |

When overloading `_[_]`/`_[_] = _`/`_[_:_]`, the method must have a correcnt signature:

- `_[_]` should have signature `(Self, Index) -> Result`, used as `let result = self[index]`
- `_[_]=_` should have signature `(Self, Index, Value) -> Unit`, used as `self[index] = value`
- `_[_:_]` should have signature `(Self, start? : Index, end? : Index) -> Result`, used as `let result = self[start:end]`

By implementing `_[_:_]` method, you can create a view for a user-defined type. Here is an example:

```moonbit
struct DataView(String)

struct Data {}

#alias("_[_:_]")
fn Data::as_view(_self : Data, start? : Int = 0, end? : Int) -> DataView {
  "[\{start}, \{end.unwrap_or(100)})"
}

test {
  let data = Data::{  }
  inspect(data[:].0, content="[0, 100)")
  inspect(data[2:].0, content="[2, 100)")
  inspect(data[:5].0, content="[0, 5)")
  inspect(data[2:5].0, content="[2, 5)")
}
```

## Trait system

MoonBit provides a trait system for overloading/ad-hoc polymorphism. Traits declare a list of operations, which must be supplied when a type wants to implement the trait. Traits can be declared as follows:

```moonbit
pub(open) trait I {
  method_(Int) -> Int
  method_with_label(Int, label~ : Int) -> Int
  //! method_with_label(Int, label?: Int) -> Int
}
```

In the body of a trait definition, a special type `Self` is used to refer to the type that implements the trait.

### Extending traits

A trait can depend on other traits, for example:

```moonbit
pub(open) trait Position {
  pos(Self) -> (Int, Int)
}

pub(open) trait Draw {
  draw(Self, Int, Int) -> Unit
}

pub(open) trait Object: Position + Draw {}
```

### Implementing traits

To implement a trait, a type must explicitly provide all the methods required by the trait
using the syntax `impl Trait for Type with method_name(...) { ... }`. For example:

```moonbit
pub(open) trait MyShow {
  to_string(Self) -> String
}

struct MyType {}

pub impl MyShow for MyType with to_string(self) {
  ...
}

struct MyContainer[_] {}

/// trait implementation with type parameters.
/// `[X : Show]` means the type parameter `X` must implement `Show`,
/// this will be covered later.
pub impl[X : MyShow] MyShow for MyContainer[X] with to_string(self) {
  ...
}
```

Type annotation can be omitted for trait `impl`: MoonBit will automatically infer the type based on the signature of `Trait::method` and the self type.

The author of the trait can also define **default implementations** for some methods in the trait, for example:

```moonbit
pub(open) trait J {
  f(Self) -> Unit
  f_twice(Self) -> Unit = _
}

impl J with f_twice(self) {
  self.f()
  self.f()
}
```

Note that in addition to the actual default implementation `impl J with f_twice`,
a mark `= _` is also required in the declaration of `f_twice` in `J`.
The `= _` mark is an indicator that this method has default implementation,
it enhances readability by allowing readers to know which methods have default implementation at first glance.

Implementers of trait `J` don't have to provide an implementation for `f_twice`: to implement `J`, only `f` is necessary.
They can always override the default implementation with an explicit `impl J for Type with f_twice`, if desired, though.

```moonbit
impl J for Int with f(self) {
  println(self)
}

impl J for String with f(self) {
  println(self)
}

impl J for String with f_twice(self) {
  println(self)
  println(self)
}

```

To implement the sub trait, one will have to implement the super traits,
and the methods defined in the sub trait. For example:

```moonbit
impl Position for Point with pos(self) {
  (self.x, self.y)
}

impl Draw for Point with draw(self, x, y) {
  ()
}

impl Object for Point

pub fn[O : Object] draw_object(obj : O) -> Unit {
  let (x, y) = Position::pos(obj)
  Draw::draw(obj, x, y)
}

test {
  let p = Point::{ x: 1, y: 2 }
  draw_object(p)
}
```

In a generic function constrained by a subtrait, call methods inherited from a
supertrait with qualified syntax such as `Position::pos(obj)`. Calling those
methods on the type parameter with dot syntax is deprecated because the method
comes from the supertrait rather than the written constraint.

For traits where all methods have default implementation,
it is still necessary to explicitly implement them,
in order to support features such as [abstract trait](https://docs.moonbitlang.com/en/latest/language/packages.html#traits).
For this purpose, MoonBit provides the syntax `impl Trait for Type` (i.e. without the method part).
`impl Trait for Type` ensures that `Type` implements `Trait`,
MoonBit will automatically check if every method in `Trait` has corresponding implementation (custom or default).

In addition to handling traits where every methods has a default implementation,
the `impl Trait for Type` can also serve as documentation, or a TODO mark before filling actual implementation.

#### WARNING
Currently, an empty trait without any method is implemented automatically.

#### Attaching trait methods with `extend`

An `impl Trait for Type` declaration records that `Type` implements `Trait`.
Use an `extend` declaration to explicitly attach selected trait methods to the
type so that they can be called with dot syntax:

```moonbit
struct MyCustomType {}

pub impl Show for MyCustomType with output(self, logger) {
  ...
}

extend MyCustomType with Show::{to_string}

fn f() -> Unit {
  let x = MyCustomType::{  }
  let _ = x.to_string()
}
```

The general form is `extend Type with Trait::{method1, method2}`. Add `pub` to
make the attached methods public; without `pub`, they are available only in the
current package. A private type may still have a private `extend` declaration.

When an attached trait method uses a default implementation, `Self` in that
implementation is specialized to `Type`. Trait-object types can also be
extended, for example `extend &Derived with Super::{method}`.

Automatically attaching every method from an `impl` is deprecated. Besides
being implicit, that behavior is not refactoring-safe: a new default method in
an upstream trait can make an existing dot call ambiguous. Library authors
should add an explicit `extend` for methods that are intended to be callable
with dot syntax, or keep using `Trait::method(value, ...)` when no method-style
API is intended.

For compatibility, v0.10.4 still performs the old implicit attachment. The
`implicit_impl_as_method` warning is disabled by default in this release and
can be enabled while migrating existing code. New code should use `extend`
rather than rely on the compatibility behavior.

If an implicitly attached method should remain callable temporarily but is not
part of the intended method-style API, add a corresponding `extend` declaration
marked with `#deprecated`. This preserves a migration path for downstream code
while directing users to qualified calls such as `Trait::method(value)`.

### Using traits

When declaring a generic function, the type parameters can be annotated with the traits they should implement, allowing the definition of constrained generic functions. For example:

```moonbit
fn[X : Eq] contains(xs : Array[X], elem : X) -> Bool {
  for x in xs {
    if x == elem {
      return true
    }
  } nobreak {
    false
  }
}
```

Without the `Eq` requirement, the expression `x == elem` in `contains` will result in a type error. Now, the function `contains` can be called with any type that implements `Eq`, for example:

```moonbit
struct Point {
  x : Int
  y : Int
}

impl Eq for Point with equal(p1, p2) {
  p1.x == p2.x && p1.y == p2.y
}

test {
  assert_false(contains([1, 2, 3], 4))
  assert_true(contains([1.5, 2.25, 3.375], 2.25))
  assert_false(contains([{ x: 2, y: 3 }], { x: 4, y: 9 }))
}
```

#### Invoke trait methods directly

Methods of a trait can be called directly via `Trait::method`. MoonBit will infer the type of `Self` and check if `Self` indeed implements `Trait`, for example:

```moonbit
test {
  assert_eq(Show::to_string(42), "42")
  assert_eq(Compare::compare(1.0, 2.5), -1)
}
```

For a future-proof concrete-type API, explicitly attach trait methods that
should support dot syntax with
[`extend`](). A regular method takes
precedence over an attached trait method. Existing implicit dot calls remain
accepted during the v0.10.4 compatibility period but are deprecated.

For type parameters, a method from the single written constraint may be called
with dot syntax. Use qualified syntax for methods inherited from a supertrait,
and for every trait method when the type parameter has multiple constraints.
This makes the selected trait unambiguous. The same principle applies to trait
objects: call supertrait methods with qualified syntax, or explicitly extend
the trait-object type.

## Trait objects

MoonBit supports runtime polymorphism via trait objects.
If `t` is of type `T`, which implements trait `I`,
one can pack the methods of `T` that implements `I`, together with `t`,
into a runtime object via `t as &I`.
When the expected type of an expression is known to be a trait object type, `as &I` can be omitted.
Trait object erases the concrete type of a value,
so objects created from different concrete types can be put in the same data structure and handled uniformly:

```moonbit
pub(open) trait Animal {
  speak(Self) -> String
}

struct Duck(String)

fn Duck::make(name : String) -> Duck {
  Duck(name)
}

impl Animal for Duck with speak(self) {
  "\{self.0}: quack!"
}

struct Fox(String)

fn Fox::make(name : String) -> Fox {
  Fox(name)
}

impl Animal for Fox with speak(_self) {
  "What does the fox say?"
}

test {
  let duck1 = Duck::make("duck1")
  let duck2 = Duck::make("duck2")
  let fox1 = Fox::make("fox1")
  let animals : Array[&Animal] = [duck1, duck2, fox1]
  debug_inspect(
    animals.map(fn(animal) { animal.speak() }),
    content=(
      #|["duck1: quack!", "duck2: quack!", "What does the fox say?"]
    ),
  )
}
```

Not all traits can be used to create objects.
"object-safe" traits' methods must satisfy the following conditions:

- `Self` must be the first parameter of a method
- There must be only one occurrence of `Self` in the type of the method (i.e. the first parameter)

Users can define new methods for trait objects, just like defining new methods for structs and enums:

```moonbit
pub(open) trait Logger {
  write_string(Self, String) -> Unit
}

pub(open) trait CanLog {
  log(Self, &Logger) -> Unit
}

fn[Obj : CanLog] &Logger::write_object(self : &Logger, obj : Obj) -> Unit {
  obj.log(self)
}

/// use the new method to simplify code
pub impl[A : CanLog, B : CanLog] CanLog for (A, B) with log(self, logger) {
  let (a, b) = self
  logger
  ..write_string("(")
  ..write_object(a)
  ..write_string(", ")
  ..write_object(b)
  .write_string(")")
}
```

## Builtin traits

MoonBit provides the following useful builtin traits:

<!-- MANUAL CHECK https://github.com/moonbitlang/core/blob/80cf250d22a5d5eff4a2a1b9a6720026f2fe8e38/builtin/traits.mbt -->
```moonbit
trait Eq {
  op_equal(Self, Self) -> Bool
}

trait Compare : Eq {
  // `0` for equal, `-1` for smaller, `1` for greater
  compare(Self, Self) -> Int
}

trait Hash {
  hash_combine(Self, Hasher) -> Unit // to be implemented
  hash(Self) -> Int // has default implementation
}

trait Show {
  output(Self, Logger) -> Unit // to be implemented
  to_string(Self) -> String // has default implementation
}

trait Default {
  default() -> Self
}
```

### Deriving builtin traits

MoonBit can automatically derive implementations for some builtin traits:

```moonbit
struct T {
  a : Int
  b : Int
} derive(Eq, Compare, Debug, Default)

test {
  let t1 = T::default()
  let t2 = T::{ a: 1, b: 1 }
  debug_inspect(t1, content="{ a: 0, b: 0 }")
  debug_inspect(t2, content="{ a: 1, b: 1 }")
  assert_false(t1 == t2)
  assert_true(t1 < t2)
}
```

See [Deriving](https://docs.moonbitlang.com/en/latest/language/derive.html) for more information about deriving traits.
