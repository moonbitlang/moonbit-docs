# MoonBit

MoonBit is an end-to-end programming language toolchain for cloud and edge computing using WebAssembly.
The IDE environment is available at <https://try.moonbitlang.com> without any installation; it does not rely on any server either.

## Status

Pre-alpha, experimental. We expect MoonBit to reach beta status next year.

## Main advantages

- Generate significantly smaller WASM output than any existing solutions. 
- Much faster runtime performance.
- State of the art compile time performance.
- Simple but practical, data oriented language design.

## Overview

A MoonBit program consists of type definitions, function definitions, and variable bindings. The entry point of every package is a special `init` function. The `init` function is special in two aspects:

1. There can be multiple `init` functions in the same package.
2. An `init` function can't be explicitly called or referred to by other functions. Instead, all `init` functions will be implicitly called when initializing a package. Therefore, `init` functions should only consist of statements.

```go
func init {
  "Hello world!".print() // OK
}

func init {
  let x = 1
  x // fail
}
```

MoonBit distinguishes between statements and expressions. In a function body, only the last clause should be an expression, which serves as a return value. For example:

```go
func foo() -> int {
  let x = 1
  x + 1 // OK
}

func foo() -> int {
  let x = 1
  x + 1 // fail
  x + 2
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
func add3(x: int, y: int, z: int)-> int {
  x + y + z
}
```

Note that the arguments and return value of top-level functions require explicit type annotations. If the return type is omitted, the function will be treated as returning the unit type.

### Local Functions

Local functions are defined using the `fn` keyword. Local functions can be named or anonymous. Type annotations can be omitted for local function definitions: they can be automatically inferred in most cases. For example:

```go
pub func foo() -> int {
  fn inc(x) { x + 1 }  // named as `inc`
  fn (x) { x + inc(2) } (6) // anonymous, instantly applied to integer literal 6
}
```

Functions, whether named or anonymous, are *lexical closures*: any identifiers without a local binding must refer to bindings from a surrounding lexical scope. For example:

```go
let x = 3
func foo(x: int) {
  fn inc()  { x + 1 } // OK, will return x + 1
  fn fail() { y + 1 } // fail: The value identifier y is unbound.
}
```

### Function Applications

A function can be applied to a list of arguments in parentheses:

```go
add3(1, 2, 7)
```

This works whether `add3` is a function defined with a name (as in the previous example), or a variable bound to a function value, as shown below:

```go
var add3 = fn(x, y, z) { x + y + z }
add3(1, 2, 7)
```

The expression `add3(1, 2, 7)` returns `10`. Any expression that evaluates to a function value is applicable:

```go
let f = fn (x) { x + 1 }
let g = fn (x) { x + 2 }
(if true { f } else { g }) (3) // OK
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

### Tuple

A tuple is a collection of finite values constructed using round brackets `()` with the elements separated by commas `,`. The order of elements matters; for example, `(1,true)` and `(true,1)` have different types. Here's an example:

```go
func pack(a: bool, b: int, c: string, d: float) -> (bool, int, string, float) {
    (a, b, c, d)
}
func init {
    let quad = pack(false, 100, "text", 3.14)
    let (bool_val, int_val, str, float_val) = quad
}
```

Tuples can be accessed via pattern matching or index:

```go
func f(t : (int, int)) {
  let (x1, y1) = t // access via pattern matching
  // access via index
  let x2 = t.0
  let y2 = t.1
  if (x1 == x2 && y1 == y2) {
    "yes".print()
  } else {
    "no".print()
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

```go
let array = [1, 2, 3, 4]
let a = array[2]
array[3] = 5
let b = a + array[3]
b.print() // prints 8
```

## Variable Binding

A variable can be declared as mutable or immutable using the keywords `var` or `let`, respectively. A mutable variable can be reassigned to a new value, while an immutable one cannot.

```go
let zero = 0

func init {
  var i = 10
  i = 20
  (i + zero).print()
}
```
There is a short-hand syntax sugar for local immutable bindings, e.g, using `:=`.

```go
func test () {
  a := 3 
  b := "hello"
}
```
## Data Types

There are two ways to create new data types: `struct` and `enum`.

### Struct

In MoonBit, structs are similar to tuples, but their fields are indexed by field names. A struct can be constructed using a struct literal, which is composed of a set of labeled values and delimited with curly brackets. The type of a struct literal can be automatically inferred if its fields exactly match the type definition. A field can be accessed using the dot syntax `s.f`. If a field is marked as mutable using the keyword `mut`, it can be assigned a new value.

```go
type user struct {
  id: int
  name: string
  mut email: string
}

func init {
  let u = { id: 0, name: "John Doe", email: "john@doe.com" }
  u.email = "john@doe.name"
  u.email.print()
}
```

Note that you can also include methods associated with your record type, for example:

```go
type stack struct { 
  mut elems: list[int]
  push: (int) => ()
  pop: (list[int]) => int
}
```

### Enum

Enum types are similar to algebraic data types in functional languages. An enum can have a set of cases. Additionally, every case can specify associated values of different types, similar to a tuple. The label for every case must be capitalized, which is called a data constructor. An enum can be constructed by calling a data constructor with arguments of specified types. The construction of an enum must be annotated with a type. An enum can be destructed by pattern matching, and the associated values can be bound to variables that are specified in each pattern.

```go
type list enum {
  Nil
  Cons (int, list)
}

func print(l: list) {
  match l {
    Nil => "nil".print()
    Cons(x, xs) => {
      x.print(); 
      ",".print(); 
      print(xs)
    }
  }
}


func init {
  let l: list = Cons(1, Cons(2, Nil))
  print(l)
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

Generics are supported in top-level function and data type definitions. Type parameters can be introduced within square brackets. We can rewrite the aforementioned data type `list` to add a type parameter `T` to obtain a generic version of lists. We can then define generic functions over lists like `map` and `reduce`.

```go
type list[T] enum {
  Nil
  Cons(T, list[T])
}

func map[S, T](self: list[S], f: (S) => T) -> list[T] {
  match self {
    Nil => Nil
    Cons(x, xs) => Cons(f(x), map(xs, f))
  }
}

func reduce[S, T](self: list[S], op: (T, S) => T, init: T) -> T {
  match self {
    Nil => init
    Cons(x, xs) => reduce(xs, op, op(init, x))
  }
}
```

## Uniform Function Call Syntax

MoonBit supports methods in a different way from traditional object-oriented languages. A method is defined as a top-level function with `self` as the name of its first parameter. The `self` parameter will be the subject of a method call. For example, `l.map(f)` is equivalent to `map(l, f)`. Such syntax enables method chaining rather than heavily nested function calls. For example, we can chain the previously defined `map` and `reduce` together with `from_array` and `output` to perform list operations using the method call syntax.

```go
func from_array[T](self: array[T]) -> list[T] {
  var res: list[T] = Nil
  var i = self.length() - 1
  while (i >= 0) {
    res = Cons(self[i], res)
    i = i - 1
  }
  res
}

func init {
  [1, 2, 3, 4, 5].from_array().map(fn(x) { x * 2 }).reduce(fn(x, y) { x + y }, 0).print()
}
```

Another difference between a method and a regular function is that overloading is only supported by the method syntax. For example, we have multiple output functions, such as `output_int` and `output_float`, for different types, but using the method `output` the type of the subject can be recognized and the appropriate overloaded version will be selected, such as `1.print()` and `1.0.print()`.

## operator overloading
MoonBit supports operator overloading of builtin operators. The method name corresponding to a operator `<op>` is `op_<op>`. For example:

```go
pub type t struct {
  x:int
}

pub func op_add(self: t, other: t) -> t {
  { x: self.x + other.x }
}

func init {
  let a = { x:0, }
  let b = { x:2, }
  (a + b).x.print()
}
```

Currently, the following operators can be overloaded:

|operator name|method name|
|---|---|
|`+`|`op_add`|
|`-`|`op_sub`|
|`*`|`op_mul`|
|`/`|`op_div`|
|`%`|`op_mod`|
|`-`(unary)|`op_neg`|
|`_[_]`(get item)|`op_get`|
|`_[_] = _`(set item)|`op_set`|

## Access Control

By default, all type definitions, function definitions, variable bindings, and struct fields are *invisible* to other packages. This design prevents unintended exposure of implementation details. To make them visible, you can use the pub modifier before `type`, `func`, `let`, `var`, or field names. However, it is important to note that:

- Struct fields cannot be defined as `pub` within a private struct since it makes no sense.
- Enum constructors do not have individual visibility so you cannot use `pub` before them.

```go
type r1 struct {  // implicitly private struct
  x: int          // implicitly private field
  pub y: int      // ERROR: a field cannot be defined as `pub` within a private struct
}

pub type r2 struct {  // explicitly public struct
  x: int              // implicitly private field
  pub y: int          // explicitly public field
}

type t1 enum {  // implicitly private enum
  A(int)        // implicitly private constructor
  pub B(int)    // ERROR: unexpected `pub`
}

pub type t2 enum {  // explicitly public enum
  A(int)            // implicitly public constructor
  pub B(int)        // ERROR: unexpected `pub`
}
```

Access control in MoonBit adheres to the principle that a `pub` type, function, or variable cannot be defined in terms of a private type. This is because the private type may not be accessible everywhere that the `pub` entity is used. MoonBit incorporates sanity checks to prevent the occurrence of use cases that violate this principle.

```go
pub type s struct {
  x: t1      // OK
  pub y: t1  // ERROR: field type `t1` is private!
}

pub func f(x: t2) -> t2  // OK
pub func f(x: t1) -> t2  // ERROR: parameter type `t1` is private!
pub func f(x: t2) -> t1  // ERROR: return type `t1` is private!

pub let a: t1  // ERROR: variable type `t1` is private!
```

## String Interpolation
String interpolation is a powerful feature in MoonBit that allows you to conveniently substitute variables within interpolated strings. With string interpolation, you can easily construct dynamic strings by embedding variable values directly into the text.

To use string interpolation in MoonBit, you can follow the syntax below:

```go
x := 42
"The answer is \(x)".print()
```

Variables used for string interpolation must support the `to_string` method.

