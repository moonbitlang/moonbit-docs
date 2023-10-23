# MoonBit

MoonBit is an end-to-end programming language toolchain for cloud and edge computing using WebAssembly. The IDE environment is available at [try.moonbitlang.com](https://try.moonbitlang.com) without any installation, and it does not rely on any server either.

## Table of Contents
- [Status](#status)
- [Main Advantages](#main-advantages)
- [Overview](#overview)
  - [MoonBit Program Structure](#moonbit-program-structure)
  - [Expressions and Statements](#expressions-and-statements)
- [Functions](#functions)
  - [Top-Level Functions](#top-level-functions)
  - [Local Functions](#local-functions)
  - [Function Applications](#function-applications)
- [Control Structures](#control-structures)
  - [Conditional Expressions](#conditional-expressions)
  - [Loops](#loops)
- [Built-in Data Structures](#built-in-data-structures)
  - [Number](#number)
  - [String](#string)
  - [Tuple](#tuple)
  - [Array](#array)
- [Variable Binding](#variable-binding)
- [Data Types](#data-types)
  - [Struct](#struct)
  - [Enum](#enum)
- [Pattern Matching](#pattern-matching)
- [Generics](#generics)
- [Uniform Function Call Syntax](#uniform-function-call-syntax)
- [Operator Overloading](#operator-overloading)
- [Access Control](#access-control)
- [Interface System](#interface-system)
- [Methods Without a Self Parameter](#methods-without-a-self-parameter)
- [MoonBit’s Build System](#moonbit’s-build-system)

## Status

Alpha, experimental. We expect MoonBit to reach beta status next year(2024).

## Main advantages

- Generate significantly smaller WASM output than any existing solutions.
- Much faster runtime performance.
- State of the art compile-time performance.
- Simple but practical, data-oriented language design.

## Overview

A MoonBit program consists of type definitions, function definitions, and variable bindings. The entry point of every package is a special `init` function. The `init` function is special in two aspects:

1. There can be multiple `init` functions in the same package.
2. An `init` function can't be explicitly called or referred to by other functions. Instead, all `init` functions will be implicitly called when initializing a package. Therefore, `init` functions should only consist of statements.

```go live
func init {
  print("Hello world!") // OK
}

func init {
  let x = 1
  // x // fail
  print(x) // success
}
```

MoonBit distinguishes between statements and expressions. In a function body, only the last clause should be an expression, which serves as a return value. For example:

```go live
func foo() -> Int {
  let x = 1
  x + 1 // OK
}

func bar() -> Int {
  let x = 1
  x + 1 // fail
  x + 2
}

func init {
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

Functions can be defined as top-level or local. We can use the `func` keyword to define a top-level function that sums three integers and returns the result, as follows:

```go
func add3(x: Int, y: Int, z: Int)-> Int {
  x + y + z
}
```

Note that the arguments and return value of top-level functions require explicit type annotations. If the return type is omitted, the function will be treated as returning the unit type.

### Local Functions

Local functions are defined using the `fn` keyword. Local functions can be named or anonymous. Type annotations can be omitted for local function definitions: they can be automatically inferred in most cases. For example:

```go live
func foo() -> Int {
  fn inc(x) { x + 1 }  // named as `inc`
  fn (x) { x + inc(2) } (6) // anonymous, instantly applied to integer literal 6
}

func init {
  print(foo())
}
```

Functions, whether named or anonymous, are *lexical closures*: any identifiers without a local binding must refer to bindings from a surrounding lexical scope. For example:

```go live
let y = 3
func foo(x: Int) {
  fn inc()  { x + 1 } // OK, will return x + 1
  fn four() { y + 1 } // Ok, will return 4
  print(inc())
  print(four())
}

func init {
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
func init {
  let add3 = fn(x, y, z) { x + y + z }
  print(add3(1, 2, 7))
}
```

The expression `add3(1, 2, 7)` returns `10`. Any expression that evaluates to a function value is applicable:

```go live
func init {
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

## Built-in Data Structures

### Number

Moonbit supports numeric literals, including decimal, binary, octal, and hexadecimal numbers.

To improve readability, you may place underscores in the middle of numeric literals such as `1_000_000`. Note that underscores can be placed anywhere within a number, not just every three digits.

- There is nothing surprising about decimal numbers.

```
let a = 1234
let b = 1_000_000 + a
let large_num = 9_223_372_036_854_775_807L // Integers of the Int64 type must have an 'L' as a suffix
```

- A binary number has a leading zero followed by a letter "B", i.e. `0b`/`0B`.
  Note that the digits after `0b`/`0B` must be `0` or `1`.

```
let bin =  0b110010
let another_bin = 0B110010
```

- An octal number has a leading zero followed by a letter "O", i.e. `0o`/`0O`.
  Note that the digits after `0o`/`0O` must be in the range from `0` through `7`:

```
let octal = 0o1234
let another_octal = 0O1234
```

- A hexadecimal number has a leading zero followed by a letter "X", i.e. `0x`/`0X`.
  Note that the digits after the `0x`/`0X` must be in the range `0123456789ABCDEF`.

```
let hex = 0XA
let another_hex = 0xA
```

### String

String interpolation is a powerful feature in MoonBit that enables you to substitute variables within interpolated strings. This feature simplifies the process of constructing dynamic strings by directly embedding variable values into the text.

```swift live
func init {
  x := 42
  print("The answer is \(x)")
}
```

Variables used for string interpolation must support the `to_string` method.

### Tuple

A tuple is a collection of finite values constructed using round brackets `()` with the elements separated by commas `,`. The order of elements matters; for example, `(1,true)` and `(true,1)` have different types. Here's an example:

```go live
func pack(a: Bool, b: Int, c: String, d: Float) -> (Bool, Int, String, Float) {
    (a, b, c, d)
}
func init {
    let quad = pack(false, 100, "text", 3.14)
    let (bool_val, int_val, str, float_val) = quad
}
```

Tuples can be accessed via pattern matching or index:

```go live
func f(t : (Int, Int)) {
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

func init {
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
func init {
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

func init {
  var i = 10
  i = 20
  print(i + zero)
}
```
There is a short-hand syntax sugar for local immutable bindings, e.g, using `:=`.

```go
func init {
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

func init {
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

### Enum

Enum types are similar to algebraic data types in functional languages. An enum can have a set of cases. Additionally, every case can specify associated values of different types, similar to a tuple. The label for every case must be capitalized, which is called a data constructor. An enum can be constructed by calling a data constructor with arguments of specified types. The construction of an enum must be annotated with a type. An enum can be destructed by pattern matching, and the associated values can be bound to variables that are specified in each pattern.

```go live
enum List {
  Nil
  Cons (Int, List)
}

func print_list(l: List) {
  match l {
    Nil => print("nil")
    Cons(x, xs) => {
      print(x)
      print(",")
      print_list(xs)
    }
  }
}

func init {
  let l: List = Cons(1, Cons(2, Nil))
  print_list(l)
}
```

## Pattern Matching

We have shown a use case of pattern matching for enums, but pattern matching is not restricted to enums. For example, we can also match expressions against Boolean values, numbers, characters, strings, tuples, arrays, and struct literals. Since there is only one case for those types other than enums, we can pattern match them using `let`/`var` binding instead of `match` expressions. Note that the scope of bound variables in `match` is limited to the case where the variable is introduced, while `let`/`var` binding will introduce every variable to the current scope. Furthermore, we can use underscores `_` as wildcards for the values we don’t care about.

```go
let id = match u {
  { id: id, name: _, email: _ } => id
}
// is equivalent to
let { id: id, name: _, email: _ } = u
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

func map[S, T](self: List[S], f: (S) -> T) -> List[T] {
  match self {
    Nil => Nil
    Cons(x, xs) => Cons(f(x), map(xs, f))
  }
}

func reduce[S, T](self: List[S], op: (T, S) -> T, init: T) -> T {
  match self {
    Nil => init
    Cons(x, xs) => reduce(xs, op, op(init, x))
  }
}
```

## Uniform Function Call Syntax

MoonBit supports methods in a different way from traditional object-oriented languages. A method is defined as a top-level function with `self` as the name of its first parameter. The `self` parameter will be the subject of a method call. For example, `l.map(f)` is equivalent to `map(l, f)`. Such syntax enables method chaining rather than heavily nested function calls. For example, we can chain the previously defined `map` and `reduce` together with `into_list` to perform list operations using the method call syntax.

```go live
func map[S, T](self: List[S], f: (S) -> T) -> List[T] {
  match self {
    Nil => Nil
    Cons(x, xs) => Cons(f(x), map(xs, f))
  }
}

func reduce[S, T](self: List[S], op: (T, S) -> T, init: T) -> T {
  match self {
    Nil => init
    Cons(x, xs) => reduce(xs, op, op(init, x))
  }
}

func into_list[T](self: Array[T]) -> List[T] {
  var res: List[T] = Nil
  var i = self.length() - 1
  while (i >= 0) {
    res = Cons(self[i], res)
    i = i - 1
  }
  res
}

func init {
  print([1, 2, 3, 4, 5].into_list().map(fn(x) { x * 2 }).reduce(fn(x, y) { x + y }, 0))
}
```

## Operator Overloading
MoonBit supports operator overloading of builtin operators. The method name corresponding to a operator `<op>` is `op_<op>`. For example:

```go live
struct T {
  x:Int
}

func op_add(self: T, other: T) -> T {
  { x: self.x + other.x }
}

func init {
  let a = { x:0, }
  let b = { x:2, }
  print((a + b).x)
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

## Access Control

By default, all function definitions and variable bindings are *invisible* to other packages; types without modifiers are abstract data types, whose name is exported but the internals are invisible. This design prevents unintended exposure of implementation details. You can use the `pub` modifier before `type`/`func`/`let` to make them fully visible, or put `priv` before `type` to make it fully invisible to other packages. You can also use `pub` or `priv` before field names to obtain finer-grained access control. However, it is important to note that:

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
func init {
  let r = { field: 4 }       // OK
  let r = { ..r, field: 8 }  // OK
}

// Package B
func print(r : RO) {
  print("{ field: ")
  print(r.field)  // OK
  print(" }")
}
func init {
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
pub func f1(_x: T3) -> T1 { T1::A(0) }
// ERROR: public function has private return type `T3`!
pub func f2(_x: T1) -> T3 { T3::A(0) }
// OK
pub func f3(_x: T1) -> T1 { T1::A(0) }

pub let a: T3  // ERROR: public variable has private type `T3`!
```

## Interface system
Moonbit features a structural interface system for overloading/ad-hoc polymorphism.
Interface can be declared as follows:

```go
interface I {
  f(Self, ...) -> ...
}
```

There is no need to implement an interface explicitly.
Types with the required methods automatically implements an interface.
For example, the following interface:

```go
interface Show {
  to_string(Self) -> String
}
```

is automatically implemented by builtin types such as `Int` and `Float`.

When declaring a generic function/method,
the type parameters can be annotated with the interface they should implement.
For example:

```go
interface Number {
  op_add(Self, Self) -> Self
  op_mul(Self, Self) -> Self
}

func square[N: Number](x: N) -> N {
  x * x
}
```

Without the `Number` requirement,
the expression `x * x` in `square` will result in a method/operator not found error.
Now, the function `square` can be called with any type that implements `Number`, for example:

```go live
func init {
  print(square(2)) // 4
  print(square(1.5)) // 2.25
  print(square({ x: 2, y: 3 })) // (4, 9)
}

struct Point {
  x: Int
  y: Int
}

func op_add(self: Point, other: Point) -> Point {
  { x: self.x + other.x, y: self.y + other.y }
}

func op_mul(self: Point, other: Point) -> Point {
  { x: self.x * other.x, y: self.y * other.y }
}

func to_string(self: Point) -> String {
  let x = self.x
  let y = self.y
  "(\(x), \(y))"
}
```

Moonbit provides the following useful builtin interfaces:

```go
interface Eq {
  op_equal(Self, Self) -> Bool
}

interface Compare {
  // `0` for equal, `-1` for smaller, `1` for greater
  op_equal(Self, Self) -> Int
}

interface Hash {
  hash(Self) -> Int
}

interface Show {
  to_string(Self) -> String
}

interface Default {
  Self::default() -> Self
}
```

## Methods without a self parameter
Sometimes it is useful to have methods that do not have a self parameter.
For example, the builtin `Default` interface describe types with a default value,
but constructing a default value should not depend on a `self` value.
So Moonbit provides a special syntax for methods without a `self` parameter:

```go live
func Int::default() -> Int {
  0
}

func init {
  print(Int::default())
}
```

Methods without `self` must be called explicitly with their type name.
Methods without `self` can be declaraed in interfaces and called with type parameters, for example:

```go
interface I {
  Self::one() -> Self
  op_add(Self, Self) -> Self
}

func two[X: I]() -> X {
  X::one() + X::one()
}
```

## MoonBit’s build system

The introduction to the build system is available at [MoonBit's Build System Tutorial](https://www.moonbitlang.com/docs/build-system-tutorial/).

