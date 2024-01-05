# MoonBit

MoonBit is an end-to-end programming language toolchain for cloud and edge computing using WebAssembly. The IDE environment is available at [https://try.moonbitlang.com](https://try.moonbitlang.com) without any installation; it does not rely on any server either.

## Status and aimed timeline

It is currently alpha, experimental. We expect MoonBit to reach *beta-preview* in 02/2024 and *beta* in 06/2024.

When MoonBit reaches beta, it means any backwards-incompatible changes will be seriously evaluated and MoonBit *can* be used in production(very rare compiler bugs). MoonBit is developed by a talented full time team who had extensive experience in building language toolchains, so we will grow much faster than the typical language ecosystem, you won't wait long to use MoonBit in your production.

## Main advantages

- Generate significantly smaller WASM output than any existing solutions.
- Much faster runtime performance.
- State of the art compile-time performance.
- Simple but practical, data-oriented language design.

## Overview

A MoonBit program consists of type definitions, function definitions, and variable bindings. The entry point of every package is a special `init` function. The `init` function is special in two aspects:

1. There can be multiple `init` functions in the same package.
2. An `init` function can't be explicitly called or referred to by other functions. Instead, all `init` functions will be implicitly called when initializing a package. Therefore, `init` functions should only consist of statements.

```rust live
fn init {
  print("Hello world!") // OK
}

fn init {
  let x = 1
  // x // fail
  print(x) // success
}
```

MoonBit distinguishes between statements and expressions. In a function body, only the last clause should be an expression, which serves as a return value. For example:

```rust live
fn foo() -> Int {
  let x = 1
  x + 1 // OK
}

fn bar() -> Int {
  let x = 1
  x + 1 // fail
  x + 2
}

fn init {
  print(foo())
  print(bar())
}
```

### Expressions and Statements

Expressions include:

- Value literals (e.g. Boolean values, numbers, characters, strings, arrays, tuples, structs)
- Arithmetical, logical, or comparison operations
- Accesses to array elements (e.g. `a[0]`) or struct fields (e.g `r.x`) or tuple components (e.g. `t.0`)
- Variables and (capitalized) enum constructors
- Anonymous local function definitions
- `match` and `if` expressions

Statements include:

- Named local function definitions
- Local variable bindings
- Assignments
- While loops and related control constructs (`break` and `continue`)
- `return` statements
- Any expression whose return type is `unit`

## Functions

Functions take arguments and produce a result. In MoonBit, functions are first-class, which means that functions can be arguments or return values of other functions.

### Top-Level Functions

Functions can be defined as top-level or local. We can use the `fn` keyword to define a top-level function that sums three integers and returns the result, as follows:

```rust
fn add3(x: Int, y: Int, z: Int)-> Int {
  x + y + z
}
```

Note that the arguments and return value of top-level functions require explicit type annotations. If the return type is omitted, the function will be treated as returning the unit type.

### Local Functions

Local functions can be named or anonymous. Type annotations can be omitted for local function definitions: they can be automatically inferred in most cases. For example:

```go live
fn foo() -> Int {
  fn inc(x) { x + 1 }  // named as `inc`
  fn (x) { x + inc(2) } (6) // anonymous, instantly applied to integer literal 6
}

fn init {
  print(foo())
}
```

Functions, whether named or anonymous, are _lexical closures_: any identifiers without a local binding must refer to bindings from a surrounding lexical scope. For example:

```go live
let y = 3
fn foo(x: Int) {
  fn inc()  { x + 1 } // OK, will return x + 1
  fn four() { y + 1 } // Ok, will return 4
  print(inc())
  print(four())
}

fn init {
  foo(2)
}
```

### Function Applications

A function can be applied to a list of arguments in parentheses:

```go
add3(1, 2, 7)
```

This works whether `add3` is a function defined with a name (as in the previous example), or a variable bound to a function value, as shown below:

```go live
fn init {
  let add3 = fn(x, y, z) { x + y + z }
  print(add3(1, 2, 7))
}
```

The expression `add3(1, 2, 7)` returns `10`. Any expression that evaluates to a function value is applicable:

```go live
fn init {
  let f = fn (x) { x + 1 }
  let g = fn (x) { x + 2 }
  print((if true { f } else { g })(3)) // OK
}
```

## Control Structures

### Conditional Expressions

A conditional expression consists of a condition, a consequent, and an optional else clause.

```go
if x == y {
  expr1
} else {
  expr2
}

if x == y {
  expr1
}
```

The else clause can also contain another if-else expression:

```go
if x == y {
  expr1
} else if z == k {
  expr2
}
```

Curly brackets are used to group multiple expressions in the consequent or the else clause.

Note that a conditional expression always returns a value in MoonBit, and the return values of the consequent and the else clause must be of the same type.

### Loops

The primary loop statement in MoonBit is the `while` loop:

```go
while x == y {
  expr1
}
```

The `while` statement doesn't yield anything; it only evaluates to `()` of unit type. MoonBit also provides the `break` and `continue` statements for controlling the flow of a loop.

```rust
var i = 0
var n = 0

while i < 10 {
  i = i + 1
  if (i == 3) {
    continue
  }

  if (i == 8) {
    break
  }
  n = n + i
}
// n = 1 + 2 + 4 + 5 + 6 + 7
println(n) // outputs 25
```

The `while` loop can have an optional "continue" block after the loop condition, separated by comma. It is executed _after_ the body of every iteration, _before_ the condition of next iteration:

```rust
var i = 0
while i < 10, i = i + 1 {
  println(i)
} // outputs 0 to 9
```

If there are multiple statements in the continue block, they must be wrapped in braces. `continue` statement in the loop body will not skip continue block. For example, the following code will output all odd numbers smaller than 10:

```rust
var i = 1
while i < 10, i = i + 1 {
  if (i % 2 == 0) {
    continue
  }
  println(i)
} // outputs 1 3 5 7 9
```

## Built-in Data Structures

### Number

MoonBit supports numeric literals, including decimal, binary, octal, and hexadecimal numbers.

To improve readability, you may place underscores in the middle of numeric literals such as `1_000_000`. Note that underscores can be placed anywhere within a number, not just every three digits.

- There is nothing surprising about decimal numbers.

```rust
let a = 1234
let b = 1_000_000 + a
let large_num = 9_223_372_036_854_775_807L // Integers of the Int64 type must have an 'L' as a suffix
```

- A binary number has a leading zero followed by a letter "B", i.e. `0b`/`0B`.
  Note that the digits after `0b`/`0B` must be `0` or `1`.

```rust
let bin =  0b110010
let another_bin = 0B110010
```

- An octal number has a leading zero followed by a letter "O", i.e. `0o`/`0O`.
  Note that the digits after `0o`/`0O` must be in the range from `0` through `7`:

```rust
let octal = 0o1234
let another_octal = 0O1234
```

- A hexadecimal number has a leading zero followed by a letter "X", i.e. `0x`/`0X`.
  Note that the digits after the `0x`/`0X` must be in the range `0123456789ABCDEF`.

```rust
let hex = 0XA
let another_hex = 0xA
```

### String

String interpolation is a powerful feature in MoonBit that enables you to substitute variables within interpolated strings. This feature simplifies the process of constructing dynamic strings by directly embedding variable values into the text.

```swift live
fn init {
  x := 42
  print("The answer is \(x)")
}
```

Variables used for string interpolation must support the `to_string` method.

### Tuple

A tuple is a collection of finite values constructed using round brackets `()` with the elements separated by commas `,`. The order of elements matters; for example, `(1,true)` and `(true,1)` have different types. Here's an example:

```go live
fn pack(a: Bool, b: Int, c: String, d: Double) -> (Bool, Int, String, Double) {
    (a, b, c, d)
}
fn init {
    let quad = pack(false, 100, "text", 3.14)
    let (bool_val, int_val, str, float_val) = quad
}
```

Tuples can be accessed via pattern matching or index:

```go live
fn f(t : (Int, Int)) {
  let (x1, y1) = t // access via pattern matching
  // access via index
  let x2 = t.0
  let y2 = t.1
  if (x1 == x2 && y1 == y2) {
    print("yes")
  } else {
    print("no")
  }
}

fn init {
  f((1, 2))
}
```

### Array

An array is a finite sequence of values constructed using square brackets `[]`, with elements separated by commas `,`. For example:

```go
let array = [1, 2, 3, 4]
```

You can use `array[x]` to refer to the xth element. The index starts from zero.

```go live
fn init {
  let array = [1, 2, 3, 4]
  let a = array[2]
  array[3] = 5
  let b = a + array[3]
  print(b) // prints 8
}
```

## Variable Binding

A variable can be declared as mutable or immutable using the keywords `var` or `let`, respectively. A mutable variable can be reassigned to a new value, while an immutable one cannot.

```go live
let zero = 0

fn init {
  var i = 10
  i = 20
  print(i + zero)
}
```

There is a short-hand syntax sugar for local immutable bindings, e.g, using `:=`.

```go
fn init {
  a := 3
  b := "hello"
  print(a)
  print(b)
}
```

## Data Types

There are two ways to create new data types: `struct` and `enum`.

### Struct

In MoonBit, structs are similar to tuples, but their fields are indexed by field names. A struct can be constructed using a struct literal, which is composed of a set of labeled values and delimited with curly brackets. The type of a struct literal can be automatically inferred if its fields exactly match the type definition. A field can be accessed using the dot syntax `s.f`. If a field is marked as mutable using the keyword `mut`, it can be assigned a new value.

```go live
struct User {
  id: Int
  name: String
  mut email: String
}

fn init {
  let u = { id: 0, name: "John Doe", email: "john@doe.com" }
  u.email = "john@doe.name"
  print(u.id)
  print(u.name)
  print(u.email)
}
```

Note that you can also include methods associated with your record type, for example:

```go
struct Stack {
  mut elems: List[Int]
  push: (Int) -> Unit
  pop: () -> Int
}
```

#### Constructing Struct with Shorthand

If you already have some variable like `name` and `email`, it's redundant to repeat those name when constructing a struct:

```go
fn init{
  let name = "john"
  let email = "john@doe.com"
  let u = { id: 0, name: name, email: email }
}
```

You can use shorthand instead, it behaves exactly the same.

```go
fn init{
  let name = "john"
  let email = "john@doe.com"
  let u = { id: 0, name, email }
}
```

#### Struct Update Syntax

It's useful to create a new struct based on an existing one, but with some fields updated.

```rust
struct User {
  id: Int
  name: String
  email: String
}

fn to_string(self : User) -> String {
  "{ id: " + self.id.to_string() +
    ", name: " + self.name +
    ", email: " + self.email + " }"
}

fn init {
  let user = { id: 0, name: "John Doe", email: "john@doe.com" }
  let updated_user = { ..user, email: "john@doe.name" }
  println(user) // output: { id: 0, name: John Doe, email: john@doe.com }
  println(updated_user) // output: { id: 0, name: John Doe, email: john@doe.name }
}
```

### Enum

Enum types are similar to algebraic data types in functional languages. An enum can have a set of cases. Additionally, every case can specify associated values of different types, similar to a tuple. The label for every case must be capitalized, which is called a data constructor. An enum can be constructed by calling a data constructor with arguments of specified types. The construction of an enum must be annotated with a type. An enum can be destructed by pattern matching, and the associated values can be bound to variables that are specified in each pattern.

```go live
enum List {
  Nil
  Cons (Int, List)
}

fn print_list(l: List) {
  match l {
    Nil => print("nil")
    Cons(x, xs) => {
      print(x)
      print(",")
      print_list(xs)
    }
  }
}

fn init {
  let l: List = Cons(1, Cons(2, Nil))
  print_list(l)
}
```

## Pattern Matching

We have shown a use case of pattern matching for enums, but pattern matching is not restricted to enums. For example, we can also match expressions against Boolean values, numbers, characters, strings, tuples, arrays, and struct literals. Since there is only one case for those types other than enums, we can pattern match them using `let`/`var` binding instead of `match` expressions. Note that the scope of bound variables in `match` is limited to the case where the variable is introduced, while `let`/`var` binding will introduce every variable to the current scope. Furthermore, we can use underscores `_` as wildcards for the values we don't care about, use `..` to ignore remaining fields of struct or elements of array.

```go
let id = match u {
  { id: id, name: _, email: _ } => id
}
// is equivalent to
let { id: id, name: _, email: _ } = u
// or
let { id: id, ..} = u
```

```go
let ary = [1,2,3,4]
let [a, b, ..] = ary // a = 1, b = 2
let [.., a, b] = ary // a = 3, b = 4
```

There are some other useful constructs in pattern matching. For example, we can use `as` to give a name to some pattern, and we can use `|` to match several cases at once. A variable name can only be bound once in a single pattern, and the same set of variables should be bound on both sides of `|` patterns.

```go
match expr {
  e as Lit(n) => ...
  Add(e1, e2) | Mul(e1, e2) => ...
  _ => ...
}
```

## Generics

Generics are supported in top-level function and data type definitions. Type parameters can be introduced within square brackets. We can rewrite the aforementioned data type `List` to add a type parameter `T` to obtain a generic version of lists. We can then define generic functions over lists like `map` and `reduce`.

```go
enum List[T] {
  Nil
  Cons(T, List[T])
}

fn map[S, T](self: List[S], f: (S) -> T) -> List[T] {
  match self {
    Nil => Nil
    Cons(x, xs) => Cons(f(x), map(xs, f))
  }
}

fn reduce[S, T](self: List[S], op: (T, S) -> T, init: T) -> T {
  match self {
    Nil => init
    Cons(x, xs) => reduce(xs, op, op(init, x))
  }
}
```

## Access Control

By default, all function definitions and variable bindings are _invisible_ to other packages; types without modifiers are abstract data types, whose name is exported but the internals are invisible. This design prevents unintended exposure of implementation details. You can use the `pub` modifier before `type`/`enum`/`struct`/`let` or top-level function to make them fully visible, or put `priv` before `type`/`enum`/`struct` to make it fully invisible to other packages. You can also use `pub` or `priv` before field names to obtain finer-grained access control. However, it is important to note that:

- Struct fields cannot be defined as `pub` within an abstract or private struct since it makes no sense.
- Enum constructors do not have individual visibility so you cannot use `pub` or `priv` before them.

```go
struct R1 {       // abstract data type by default
  x: Int          // implicitly private field
  pub y: Int      // ERROR: `pub` field found in an abstract type!
  priv z: Int     // WARNING: `priv` is redundant!
}

pub struct R2 {       // explicitly public struct
  x: Int              // implicitly public field
  pub y: Int          // WARNING: `pub` is redundant!
  priv z: Int         // explicitly private field
}

priv struct R3 {       // explicitly private struct
  x: Int               // implicitly private field
  pub y: Int           // ERROR: `pub` field found in a private type!
  priv z: Int          // WARNING: `priv` is redundant!
}

enum T1 {       // abstract data type by default
  A(Int)        // implicitly private variant
  pub B(Int)    // ERROR: no individual visibility!
  priv C(Int)   // ERROR: no individual visibility!
}

pub enum T2 {       // explicitly public enum
  A(Int)            // implicitly public variant
  pub B(Int)        // ERROR: no individual visibility!
  priv C(Int)       // ERROR: no individual visibility!
}

priv enum T3 {       // explicitly private enum
  A(Int)             // implicitly private variant
  pub B(Int)         // ERROR: no individual visibility!
  priv C(Int)        // ERROR: no individual visibility!
}
```

Another useful feature supported in MoonBit is `pub(readonly)` types, which are inspired by [private types](https://v2.ocaml.org/manual/privatetypes.html) in OCaml. In short, values of `pub(readonly)` types can be destructed by pattern matching and the dot syntax, but cannot be constructed or mutated in other packages. Note that there is no restriction within the same package where `pub(readonly)` types are defined.

```go
// Package A
pub(readonly) struct RO {
  field: Int
}
fn init {
  let r = { field: 4 }       // OK
  let r = { ..r, field: 8 }  // OK
}

// Package B
fn print(r : RO) {
  print("{ field: ")
  print(r.field)  // OK
  print(" }")
}
fn init {
  let r : RO = { field: 4 }  // ERROR: Cannot create values of the public read-only type RO!
  let r = { ..r, field: 8 }  // ERROR: Cannot mutate a public read-only field!
}
```

Access control in MoonBit adheres to the principle that a `pub` type, function, or variable cannot be defined in terms of a private type. This is because the private type may not be accessible everywhere that the `pub` entity is used. MoonBit incorporates sanity checks to prevent the occurrence of use cases that violate this principle.

```go
pub struct S {
  x: T1  // OK
  y: T2  // OK
  z: T3  // ERROR: public field has private type `T3`!
}

// ERROR: public function has private parameter type `T3`!
pub fn f1(_x: T3) -> T1 { T1::A(0) }
// ERROR: public function has private return type `T3`!
pub fn f2(_x: T1) -> T3 { T3::A(0) }
// OK
pub fn f3(_x: T1) -> T1 { T1::A(0) }

pub let a: T3  // ERROR: public variable has private type `T3`!
```

## Method system

MoonBit supports methods in a different way from traditional object-oriented languages. A method in MoonBit is just a toplevel function associated with a type constructor. Methods can be defined using the syntax `fn TypeName::method_name(...) -> ...`:

```rust
enum MyList[X] {
  Nil,
  Cons(X, MyList[X])
}

fn MyList::map[X, Y](xs: MyList[X], f: (X) -> Y) -> MyList[Y] { ... }
fn MyList::concat[X](xs: MyList[MyList[X]]) -> MyList[X] { ... }
```

As a convenient shorthand, when the first parameter of a function is named `self`, MoonBit automatically defines the function as a method of the type of `self`:

```rust
fn map[X, Y](self: MyList[X], f: (X) -> Y) -> List[Y] { ... }
// equivalent to
fn MyList::map[X, Y](xs: MyList[X], f: (X) -> Y) -> List[Y] { ... }
```

Methods are just regular functions owned by a type constructor. So when there is no ambiguity, methods can be called using regular function call syntax directly:

```rust
fn init {
  let xs: MyList[MyList[_]] = ...
  let ys = concat(xs)
}
```

Unlike regular functions, methods support overloading: different types can define methods of the same name. If there are multiple methods of the same name (but for different types) in scope, one can still call them by explicitly adding a `TypeName::` prefix:

```rust
struct T1 { x1: Int }
fn T1::default() -> { { x1: 0 } }

struct T2 { x2: Int }
fn T2::default() -> { { x2: 0 } }

fn init {
  // default() is ambiguous!
  let t1 = T1::default() // ok
  let t2 = T2::default() // ok
}
```

When the first parameter of a method is also the type it belongs to, methods can be called using dot syntax `x.method(...)`. MoonBit automatically finds the correct method based on the type of `x`, there is no need to write the type name and even the package name of the method:

```rust
// a package named @list
enum List[X] { ... }
fn List::length[X](xs: List[X]) -> Int { ... }

// another package that uses @list
fn init {
  let xs: @list.List[_] = ...
  debug(xs.length()) // always work
  debug(@list.List::length(xs)) // always work, but verbose
  debug(@list.length(xs)) // simpler, but only possible when there is no ambiguity in @list
}
```

## Operator Overloading

MoonBit supports operator overloading of builtin operators via methods. The method name corresponding to a operator `<op>` is `op_<op>`. For example:

```rust
struct T {
  x:Int
} derive(Debug)

fn op_add(self: T, other: T) -> T {
  { x: self.x + other.x }
}

fn init {
  let a = { x: 0 }
  let b = { x: 2 }
  debug(a + b)
}
```

Currently, the following operators can be overloaded:

| operator name        | method name |
| -------------------- | ----------- |
| `+`                  | `op_add`    |
| `-`                  | `op_sub`    |
| `*`                  | `op_mul`    |
| `/`                  | `op_div`    |
| `%`                  | `op_mod`    |
| `-`(unary)           | `op_neg`    |
| `_[_]`(get item)     | `op_get`    |
| `_[_] = _`(set item) | `op_set`    |

## Trait system

MoonBit features a structural trait system for overloading/ad-hoc polymorphism. Traits can be declared as follows:

```rust
trait I {
  method(...) -> ...
}
```

In the body of a trait definition, a special type `Self` is used to refer to the type that implements the trait.

There is no need to implement a trait explicitly. Types with the required methods automatically implements a trait. For example, the following trait:

```rust
trait Show {
  to_string(Self) -> String
}
```

is automatically implemented by builtin types such as `Int` and `Double`.

When declaring a generic function, the type parameters can be annotated with the traits they should implement, allowing the definition of constrained generic functions. For example:

```rust
trait Number {
  op_add(Self, Self) -> Self
  op_mul(Self, Self) -> Self
}

fn square[N: Number](x: N) -> N {
  x * x
}
```

Without the `Number` requirement, the expression `x * x` in `square` will result in a method/operator not found error. Now, the function `square` can be called with any type that implements `Number`, for example:

```rust
fn init {
  debug(square(2)) // 4
  debug(square(1.5)) // 2.25
  debug(square({ x: 2, y: 3 })) // (4, 9)
}

struct Point {
  x: Int
  y: Int
} derive(Debug)

fn op_add(self: Point, other: Point) -> Point {
  { x: self.x + other.x, y: self.y + other.y }
}

fn op_mul(self: Point, other: Point) -> Point {
  { x: self.x * other.x, y: self.y * other.y }
}
```

MoonBit provides the following useful builtin traits:

```rust
trait Eq {
  op_equal(Self, Self) -> Bool
}

trait Compare {
  // `0` for equal, `-1` for smaller, `1` for greater
  op_equal(Self, Self) -> Int
}

trait Hash {
  hash(Self) -> Int
}

trait Show {
  to_string(Self) -> String
}

trait Default {
  default() -> Self
}

trait Debug {
  // write debug information of [self] to a buffer
  debug_write(Self, Buffer)
}
```

## Access control of methods and extension methods

To make the trait system coherent (i.e. there is a globally unique implementation for every `Type: Trait` pair), and prevent third-party packages from modifying behavior of existing programs by accident, *only the the package that defines a type can define methods for it*. So one cannot define new methods or override old methods for builtin and foreign types.

However, it is often useful to extend the functionality of an existing type. So MoonBit provides a mechanism called extension method, defined using the syntax `fn Trait::method_name(...) -> ...`. Extension methods extend the functionality of an existing type by implementing a trait. For example, to implement a new trait `ToMyBinaryProtocol` for builtin types, one can (and must) use extension methods:

```rust
trait ToMyBinaryProtocol {
  to_my_binary_protocol(Self, Buffer)
}

fn ToMyBinaryProtocol::to_my_binary_protocol(x: Int, b: Buffer) { ... }
fn ToMyBinaryProtocol::to_my_binary_protocol(x: Double, b: Buffer) { ... }
fn ToMyBinaryProtocol::to_my_binary_protocol(x: String, b: Buffer) { ... }
```

When searching for the implementation of a trait, extension methods have a higher priority, so they can be used to override ordinary methods with undesirable behavior. Extension methods can only be used to implement the specified trait. They cannot be called directly like ordinary methods. Furthermore, *only the package of the type or the package of the trait can implement extension methods*. For example, only `@pkg1` and `@pkg2` are allowed to implement an extension method `@pkg1.Trait::f` for type `@pkg2.Type`. This restriction ensures that MoonBit's trait system is still coherent with the extra flexibility of extension methods.

## Automatically derive builtin traits

MoonBit can automatically derive implementations for some builtin traits:

```rust
struct T {
  x: Int
  y: Int
} derive(Eq, Compare, Debug, Default)

fn init {
  let t1 = T::default()
  let t2 = { x: 1, y: 1 }
  debug(t1) // {x: 0, y: 0}
  debug(t2) // {x: 1, y: 1}
  debug(t1 == t2) // false
  debug(t1 < t2) // true
}
```

## MoonBit's build system

The introduction to the build system is available at [MoonBit's Build System Tutorial](./build-system-tutorial.md).
