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

Note that the arguments and return value of top-level functions require explicit type annotations.

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
fn foo(x: Int) -> Unit {
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

### Labelled arguments
Functions can declare labelled argument with the syntax `~label : Type`. `label` will also serve as parameter name inside function body:

```rust
fn labelled(~arg1 : Int, ~arg2 : Int) -> Int {
  arg1 + arg2
}
```

Labelled arguments can be supplied via the syntax `label=arg`. `label=label` can be abbreviated as `~label`:

```rust
fn init {
  let arg1 = 1
  println(labelled(arg2=2, ~arg1)) // 3
}
```

Labelled function can be supplied in any order. The evaluation order of arguments is the same as the order of parameters in function declaration.

### Optional arguments
A labelled argument can be made optional by supplying a default expression with the syntax `~label : Type = default_expr`. If this argument is not supplied at call site, the default expression will be used:

```rust live
fn optional(~opt : Int = 42) -> Int {
  opt
}

fn init {
  println(optional()) // 42
  println(optional(opt=0)) // 0
}
```

The default expression will be evaluated everytime it is used. And the side effect in the default expression, if any, will also be triggered. For example:

```rust live
fn incr(~counter : Ref[Int] = { val: 0 }) -> Ref[Int] {
  counter.val = counter.val + 1
  counter
}

fn init {
  println(incr()) // 1
  println(incr()) // still 1, since a new reference is created everytime default expression is used
  let counter : Ref[Int] = { val: 0 }
  println(incr(~counter)) // 1
  println(incr(~counter)) // 2, since the same counter is used
}
```

If you want to share the result of default expression between different function calls, you can lift the default expression to a toplevel `let` declaration:

```rust live
let default_counter : Ref[Int] = { val: 0 }

fn incr(~counter : Ref[Int] = default_counter) -> Int {
  counter.val = counter.val + 1
  counter.val
}

fn init {
  println(incr()) // 1
  println(incr()) // 2
}
```

Default expression can depend on the value of previous arguments. For example:

```rust
fn sub_array[X](xs : Array[X], ~offset : Int, ~len : Int = xs.length() - offset) -> Array[X] {
  ... // take a sub array of [xs], starting from [offset] with length [len]
}

fn init {
  println(sub_array([1, 2, 3], offset=1)) // [2, 3]
  println(sub_array([1, 2, 3], offset=1, len=1)) // [2]
}
```

### Autofill arguments
MoonBit supports filling specific types of arguments automatically at different call site, such as the source location of a function call.
To declare an autofill argument, simply declare an optional argument with `_` as default value.
Now if the argument is not explicitly supplied, MoonBit will automatically fill it at the call site.

Currently MoonBit supports two types of autofill arguments, `SourceLoc`, which is the source location of the whole function call,
and `ArgsLoc`, which is a array containing the source location of each argument, if any:

```rust
fn f(_x : Int, _y : Int, ~loc : SourceLoc = _, ~args_loc : ArgsLoc = _) -> Unit {
  println("loc of whole function call: \(loc)")
  println("loc of arguments: \(args_loc)")
}

fn init {
  f(1, 2)
  // loc of whole function call: <filename>:7:3-7:10
  // loc of arguments: [Some(<filename>:7:5-7:6), Some(<filename>:7:8-7:9), None, None]
}
```

Autofill arguments are very useful for writing debugging and testing utilities.

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


### Functional loop

Functional loop is a powerful feature in MoonBit that enables you to write loops in a functional style.

A functional loop consumes arguments and returns a value. It is defined using the `loop` keyword, followed by its arguments and the loop body. The loop body is a sequence of clauses, each of which consists of a pattern and an expression. The clause whose pattern matches the input will be executed, and the loop will return the value of the expression. If no pattern matches, the loop will panic. Use the `continue` keyword with arguments to start the next iteration of the loop. Use the `break` keyword with arguments to return a value from the loop. The `break` keyword can be omitted if the value is the last expression in the loop body.

```rust live
fn sum(xs: List[Int]) -> Int {
  loop xs, 0 {
    Nil, acc => break acc // break can be omitted
    Cons(x, rest), acc => continue rest, x + acc
  }
}

fn init {
  println(sum(Cons(1, Cons(2, Cons(3, Nil)))))
}
```

### While loop

In MoonBit, `while` loop can be used to execute a block of code repeatedly as long as a condition is true. The condition is evaluated before executing the block of code. The `while` loop is defined using the `while` keyword, followed by a condition and the loop body. The loop body is a sequence of statements. The loop body is executed as long as the condition is true.

```go
while x == y {
  expr1
}
```

The `while` statement doesn't yield anything; it only evaluates to `()` of unit type. MoonBit also provides the `break` and `continue` statements for controlling the flow of a loop.

```rust
let mut i = 0
let mut n = 0

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

## Built-in Data Structures

### Boolean

MoonBit has a built-in boolean type, which has two values: `true` and `false`. The boolean type is used in conditional expressions and control structures.

```rust
let a = true
let b = false
let c = a && b
let d = a || b
let e = not(a)
```

### Number

MoonBit have integer type and floating point type:

| type     | description                               |  example |
| -------- | ----------------------------------------- | -------- |
| `Int`    | 32-bit signed integer                     | `42`     |
| `Int64`  | 64-bit signed integer                     | `1000L`  |
| `UInt`   | 32-bit unsigned integer                   | `14U`    |
| `Double` | 64-bit floating point, defined by IEEE754 | `3.14`   |

MoonBit also supports numeric literals, including decimal, binary, octal, and hexadecimal numbers.

To improve readability, you may place underscores in the middle of numeric literals such as `1_000_000`. Note that underscores can be placed anywhere within a number, not just every three digits.

- There is nothing surprising about decimal numbers.

```rust
let a = 1234
let b = 1_000_000 + a
let large_num = 9_223_372_036_854_775_807L // Integers of the Int64 type must have an 'L' as a suffix
let unsigned_num = 4_294_967_295U // Integers of the UInt type must have an 'U' suffix
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

`String` holds a sequence of UTF-16 code units. You can use double quotes to create a string, or use `#|` to write a multi-line string.

```rust
let a = "兔rabbit"
println(a[0]) // output: 兔
println(a[1]) // output: r
```

```rust
let b =
  #| Hello
  #| MoonBit
  #|
```

In double quotes string, a backslash followed by certain special characters forms an escape sequence:

| escape sequences     | description                                          |
| -------------------- | ---------------------------------------------------- |
| `\n`,`\r`,`\t`,`\b`  | New line, Carriage return, Horizontal tab, Backspace |
| `\\`                 | Backslash                                            |
| `\x41`               | Hexadecimal escape sequence                          |
| `\o102`              | Octal escape sequence                                |
| `\u5154`,`\u{1F600}` | Unicode escape sequence                              |


MoonBit supports string interpolation. It enables you to substitute variables within interpolated strings. This feature simplifies the process of constructing dynamic strings by directly embedding variable values into the text.

```swift live
fn init {
  let x = 42
  print("The answer is \(x)")
}
```

Variables used for string interpolation must support the `to_string` method.

### Char

`Char` is an integer representing a Unicode code point.

```rust
let a : Char = 'A'
let b = '\x41'
let c = '🐰'
```

### Byte

A byte literal in MoonBit is either a single ASCII character or a single escape enclosed in single quotes `'`, and preceded by the character `b`. Byte literals are of type `Byte`. For example:

```rust live
fn init {
  let b1 : Byte = b'a'
  println(b1.to_int())
  let b2 = b'\xff'
  println(b2.to_int())
}
```

### Tuple

A tuple is a collection of finite values constructed using round brackets `()` with the elements separated by commas `,`. The order of elements matters; for example, `(1,true)` and `(true,1)` have different types. Here's an example:

```go live
fn pack(a: Bool, b: Int, c: String, d: Double) -> (Bool, Int, String, Double) {
    (a, b, c, d)
}
fn init {
    let quad = pack(false, 100, "text", 3.14)
    let (bool_val, int_val, str, float_val) = quad
    println("\(bool_val) \(int_val) \(str) \(float_val)")
}
```

Tuples can be accessed via pattern matching or index:

```go live
fn f(t : (Int, Int)) -> Unit {
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
let numbers = [1, 2, 3, 4]
```

You can use `numbers[x]` to refer to the xth element. The index starts from zero.

```go live
fn init {
  let numbers = [1, 2, 3, 4]
  let a = numbers[2]
  numbers[3] = 5
  let b = a + numbers[3]
  print(b) // prints 8
}
```

## Variable Binding

A variable can be declared as mutable or immutable using `let mut` or `let`, respectively. A mutable variable can be reassigned to a new value, while an immutable one cannot.

```go live
let zero = 0

fn init {
  let mut i = 10
  i = 20
  print(i + zero)
}
```

## Data Types

There are two ways to create new data types: `struct` and `enum`.

### Struct

In MoonBit, structs are similar to tuples, but their fields are indexed by field names. A struct can be constructed using a struct literal, which is composed of a set of labeled values and delimited with curly brackets. The type of a struct literal can be automatically inferred if its fields exactly match the type definition. A field can be accessed using the dot syntax `s.f`. If a field is marked as mutable using the keyword `mut`, it can be assigned a new value.

```rust live
struct User {
  id: Int
  name: String
  mut email: String
}

fn init {
  let u = { id: 0, name: "John Doe", email: "john@doe.com" }
  u.email = "john@doe.name"
  println(u.id)
  println(u.name)
  println(u.email)
}
```

#### Constructing Struct with Shorthand

If you already have some variable like `name` and `email`, it's redundant to repeat those names when constructing a struct:

```go live
fn init{
  let name = "john"
  let email = "john@doe.com"
  let u = { id: 0, name: name, email: email }
}
```

You can use shorthand instead, it behaves exactly the same.

```go live
fn init{
  let name = "john"
  let email = "john@doe.com"
  let u = { id: 0, name, email }
}
```

#### Struct Update Syntax

It's useful to create a new struct based on an existing one, but with some fields updated.

```rust live
struct User {
  id: Int
  name: String
  email: String
} derive(Debug)

fn init {
  let user = { id: 0, name: "John Doe", email: "john@doe.com" }
  let updated_user = { ..user, email: "john@doe.name" }
  debug(user)         // output: { id: 0, name: "John Doe", email: "john@doe.com" }
  debug(updated_user) // output: { id: 0, name: "John Doe", email: "john@doe.name" }
}
```

### Enum

Enum types are similar to algebraic data types in functional languages. Users familiar with C/C++ may prefer calling it tagged union.

An enum can have a set of cases (constructors). Constructor names must start with capitalized letter. You can use these names to construct corresponding cases of an enum, or checking which branch an enum value belongs to in pattern matching:

```rust live
// An enum type that represents the ordering relation between two values,
// with three cases "Smaller", "Greater" and "Equal"
enum Relation {
  Smaller
  Greater
  Equal
}

// compare the ordering relation between two integers
fn compare_int(x: Int, y: Int) -> Relation {
  if x < y {
    // when creating an enum, if the target type is known, you can write the constructor name directly
    Smaller
  } else if x > y {
    // but when the target type is not known,
    // you can always use `TypeName::Constructor` to create an enum unambiguously
    Relation::Greater
  } else {
    Equal
  }
}

// output a value of type `Relation`
fn print_relation(r: Relation) -> Unit {
  // use pattern matching to decide which case `r` belongs to
  match r {
    // during pattern matching, if the type is known, writing the name of constructor is sufficient
    Smaller => println("smaller!")
    // but you can use the `TypeName::Constructor` syntax for pattern matching as well
    Relation::Greater => println("greater!")
    Equal => println("equal!")
  }
}

fn init {
  print_relation(compare_int(0, 1)) // smaller!
  print_relation(compare_int(1, 1)) // equal!
  print_relation(compare_int(2, 1)) // greater!
}
```

Enum cases can also carry payload data. Here's an example of defining an integer list type using enum:

```rust live
enum List {
  Nil
  // constructor `Cons` carries additional payload: the first element of the list,
  // and the remaining parts of the list
  Cons (Int, List)
}

fn init {
  // when creating values using `Cons`, the payload of by `Cons` must be provided
  let l: List = Cons(1, Cons(2, Nil))
  println(is_singleton(l))
  print_list(l)
}

fn print_list(l: List) -> Unit {
  // when pattern-matching an enum with payload,
  // in additional to deciding which case a value belongs to
  // you can extract the payload data inside that case
  match l {
    Nil => print("nil")
    // Here `x` and `xs` are defining new variables instead of referring to existing variables,
    // if `l` is a `Cons`, then the payload of `Cons` (the first element and the rest of the list)
    // will be bind to `x` and `xs
    Cons(x, xs) => {
      print(x)
      print(",")
      print_list(xs)
    }
  }
}

// In addition to binding payload to variables,
// you can also continue matching payload data inside constructors.
// Here's a function that decides if a list contains only one element
fn is_singleton(l: List) -> Bool {
  match l {
    // This branch only matches values of shape `Cons(_, Nil)`, i.e. lists of length 1
    Cons(_, Nil) => true
    // Use `_` to match everything else
    _ => false
  }
}
```

#### Constructor with labelled arguments
Enum constructors can have labelled argument:
```rust live
enum E {
  // `x` and `y` are alabelled argument
  C(~x : Int, ~y : Int)
}

// pattern matching constructor with labelled arguments
fn f(e : E) -> Unit {
  match e {
    // `label=pattern`
    C(x=0, y=0) => println("0!")
    // `~x` is an abbreviation for `x=x`
    // Unmatched labelled arguments can be omitted via `..`
    C(~x, ..) => println(x)
  }
}

// creating constructor with labelled arguments
fn init {
  f(C(x=0, y=0)) // `label=value`
  let x = 0
  f(C(~x, y=1)) // `~x` is an abbreviation for `x=x`
}
```

It is also possible to access labelled arguments of constructors like accessing struct fields in pattern matching:
```rust live
enum Object {
  Point(~x : Double, ~y : Double)
  Circle(~x : Double, ~y : Double, ~radius : Double)
}

fn distance_with(self : Object, other : Object) -> Double {
  match (self, other) {
    // For variables defined via `Point(..) as p`,
    // the compiler knows it must be of constructor `Point`,
    // so you can access fields of `Point` directly via `p.x`, `p.y` etc.
    (Point(_) as p1, Point(_) as p2) => {
      let dx = p2.x - p1.x
      let dy = p2.y - p1.y
      (dx * dx + dy * dy).sqrt()
    }
    (Point(_), Circle(_)) | (Circle(_) | Point(_)) | (Circle(_), Circle(_)) => abort("not implemented")
  }
}

fn init {
  let p1 : Point = Point(x=0, y=0)
  let p2 : Point = Point(x=3, y=4)
  println(p1.distance_with(p2)) // 5.0
}
```

#### Constructor with mutable fields
It is also possible to define mutable fields for constructor. This is especially useful for defining imperative data structures:
```rust live
// A mutable binary search tree with parent pointer
enum Tree[X] {
  Nil
  // only labelled arguments can be mutable
  Node(mut ~value : X, mut ~left : Tree[X], mut ~right : Tree[X], mut ~parent : Tree[X])
}

// A set implemented using mutable binary search tree.
struct Set[X] {
  mut root : Tree[X]
}

fn Set::insert[X : Compare](self : Set[X], x : X) -> Unit {
  self.root = self.root.insert(x, parent=Nil)
}

// In-place insert a new element to a binary search tree.
// Return the new tree root
fn Tree::insert[X : Compare](self : Tree[X], x : X, ~parent : Tree[X]) -> Tree[X] {
  match self {
    Nil => Node(value=x, left=Nil, right=Nil, ~parent)
    Node(_) as node => {
      let order = x.compare(node.value)
      if order == 0 {
        // mutate the field of a constructor
        node.value = x
      } else if order < 0 {
        // cycle between `node` and `node.left` created here
        node.left = node.left.insert(x, parent=node)
      } else {
        node.right = node.right.insert(x, parent=node)
      }
      // The tree is non-empty, so the new root is just the original tree
      node
    }
  }
}
```

### Newtype

MoonBit supports a special kind of enum called newtype:

```rust
// `UserId` is a fresh new type different from `Int`, and you can define new methods for `UserId`, etc.
// But at the same time, the internal representation of `UserId` is exactly the same as `Int`
type UserId Int
type UserName String
```

Newtypes are similar to enums with only one constructor (with the same name as the newtype itself). So, you can use the constructor to create values of newtype, or use pattern matching to extract the underlying representation of a newtype:

```rust
fn init {
  let id: UserId = UserId(1)
  let name: UserName = UserName("John Doe")
  let UserId(uid) = id       // the type of `uid` is `Int`
  let UserName(uname) = name // the type of `uname` is `String`
  println(uid)
  println(uname)
}
```

Besides pattern matching, you can also use `.0` to extract the internal representation of newtypes:

```rust
fn init {
  let id: UserId = UserId(1)
  let uid: Int = id.0
  println(uid)
}
```

## Pattern Matching

We have shown a use case of pattern matching for enums, but pattern matching is not restricted to enums. For example, we can also match expressions against Boolean values, numbers, characters, strings, tuples, arrays, and struct literals. Since there is only one case for those types other than enums, we can pattern match them using `let` binding instead of `match` expressions. Note that the scope of bound variables in `match` is limited to the case where the variable is introduced, while `let` binding will introduce every variable to the current scope. Furthermore, we can use underscores `_` as wildcards for the values we don't care about, use `..` to ignore remaining fields of struct or elements of array.

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
  Lit(n) as a => ...
  Add(e1, e2) | Mul(e1, e2) => ...
  _ => ...
}
```

### Map Pattern
MoonBit allows convenient matching on map-like data structures:
```rust
match map {
  // matches if any only if "b" exists in `map`
  { "b": Some(_) } => ..
  // matches if and only if "b" does not exist in `map` and "a" exists in `map`.
  // When matches, bind the value of "a" in `map` to `x`
  { "b": None, "a": Some(x) } => ..
  // compiler reports missing case: { "b": None, "a": None }
}
```

- To match a data type `T` using map pattern, `T` must have a method `op_get(Self, K) -> Option[V]` for some type `K` and `V`.
- Currently, the key part of map pattern must be a constant
- Map patterns are always open: unmatched keys are silently ignored
- Map pattern will be compiled to efficient code: every key will be fetched at most once

## Error Handling
The return type of a function can include an error type to indicate that the function might return an error. For example, the following function declaration indicates that the function div might return an error of type String:

```rust
fn div(x: Int, y: Int) -> Int!String { 
  if y == 0 {
    raise "division by zero"
  }
  x / y
}
```

The keyword `raise` is used to interrupt the function execution and return an error. There are three ways to handle errors in functions:

* Using the `!!` suffix to panic directly in case of an error, for example:

```rust
fn div_unsafe(x: Int, y: Int) -> Int {
  div(x, y)!! // Panic if `div` raised an error
}
```

* Using the `!` suffix to rethrow the error directly in case of an error, for example:

```rust
fn div_reraise(x: Int, y: Int) -> Int!String {
  div(x, y)! // Rethrow the error if `div` raised an error
}
```

* Using `try` and `catch` to catch and handle errors, for example:

```rust
fn div_with_default(x: Int, y: Int, default: Int) -> Int {
  try {
    div(x, y)!
  } catch {
    s => { println(s); default }
  }
}
```

Here, `try` is used to call a function that might throw an error, and `catch` is used to match and handle the caught error. If no error is caught, the catch block will not be executed.

In MoonBit, error types and error handling are second-class citizens, so error types can only appear in the return value of functions and cannot be used as the type of variables. Error handling with the `!` or `!!` suffix can only be used at the function call site and not in other expressions. Valid usage forms include:

```rust
f(x)!
x.f()!
(x |> f)!
(x + y)!
```

Additionally, if the return type of a function includes an error type, the function call must use `!` or `!!` for error handling, otherwise the compiler will report an error.

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
fn print(r : RO) -> Unit {
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
  Nil
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

```rust live
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

```rust live
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

Another example about `op_get` and `op_set`:

```rust live
struct Coord {
  mut x: Int
  mut y: Int
} derive(Debug)

fn op_get(self: Coord, key: String) -> Int {
  match key {
    "x" => self.x
    "y" => self.y
  }
}

fn op_set(self: Coord, key: String, val: Int) -> Unit {
    match key {
    "x" => self.x = val
    "y" => self.y = val
  }
}

fn init {
  let c = { x: 1, y: 2 }
  debug(c)
  debug(c["y"])
  c["x"] = 23
  debug(c)
  debug(c["x"])
}
```

Currently, the following operators can be overloaded:

| operator name        | method name  |
| -------------------- | ------------ |
| `+`                  | `op_add`     |
| `-`                  | `op_sub`     |
| `*`                  | `op_mul`     |
| `/`                  | `op_div`     |
| `%`                  | `op_mod`     |
| `=`                  | `op_eual`    |
| `-`(unary)           | `op_neg`     |
| `_[_]`(get item)     | `op_get`     |
| `_[_] = _`(set item) | `op_set`     |
| `_[_.._] = _`(slice) | `op_as_view` |

## Pipe operator
MoonBit provides a convenient pipe operator `|>`, which can be used to chain regular function calls:

```rust
fn init {
  x |> f // equivalent to f(x)
  x |> f(y) // equivalent to f(x, y)

  // Chain calls at multiple lines
  arg_val
  |> f1 // equivalent to f1(arg_val)
  |> f2(other_args) // equivalent to f2(f1(arg_val), other_args)
}
```

## Trait system

MoonBit features a structural trait system for overloading/ad-hoc polymorphism. Traits declare a list of operations, which must be supplied when a type wants to implement the trait. Traits can be declared as follows:

```rust
trait I {
  method(...) -> ...
}
```

In the body of a trait definition, a special type `Self` is used to refer to the type that implements the trait.

To implement a trait, a type must provide all the methods required by the trait.
However, there is no need to implement a trait explicitly. Types with the required methods automatically implements a trait. For example, the following trait:

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

Methods of a trait can be called directly via `Trait::method`. MoonBit will infer the type of `Self` and check if `Self` indeed implements `Trait`, for example:

```rust live
fn init {
  println(Show::to_string(42))
  debug(Compare::compare(1.0, 2.5))
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
  debug_write(Self, Buffer) -> Unit
}
```

## Access control of methods and extension methods

To make the trait system coherent (i.e. there is a globally unique implementation for every `Type: Trait` pair), and prevent third-party packages from modifying behavior of existing programs by accident, *only the package that defines a type can define methods for it*. So one cannot define new methods or override old methods for builtin and foreign types.

However, it is often useful to extend the functionality of an existing type. So MoonBit provides a mechanism called extension method, defined using the syntax `fn Trait::method_name(...) -> ...`. Extension methods extend the functionality of an existing type by implementing a trait. For example, to implement a new trait `ToMyBinaryProtocol` for builtin types, one can (and must) use extension methods:

```rust
trait ToMyBinaryProtocol {
  to_my_binary_protocol(Self, Buffer) -> Unit
}

fn ToMyBinaryProtocol::to_my_binary_protocol(x: Int, b: Buffer) -> Unit { ... }
fn ToMyBinaryProtocol::to_my_binary_protocol(x: Double, b: Buffer) -> Unit { ... }
fn ToMyBinaryProtocol::to_my_binary_protocol(x: String, b: Buffer) -> Unit { ... }
```

When searching for the implementation of a trait, extension methods have a higher priority, so they can be used to override ordinary methods with undesirable behavior. Extension methods can only be used to implement the specified trait. They cannot be called directly like ordinary methods. Furthermore, *only the package of the type or the package of the trait can implement extension methods*. For example, only `@pkg1` and `@pkg2` are allowed to implement an extension method `@pkg1.Trait::f` for type `@pkg2.Type`. This restriction ensures that MoonBit's trait system is still coherent with the extra flexibility of extension methods.

To invoke an extension method directly, use the `Trait::method` syntax.

```rust live
trait MyTrait {
  f(Self) -> Unit
}

fn MyTrait::f(self: Int) -> Unit {
  println("Got Int \(self)!")
}

fn init {
  MyTrait::f(42)
}
```


## Automatically derive builtin traits

MoonBit can automatically derive implementations for some builtin traits:

```rust live
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

## Trait objects
MoonBit supports runtime polymorphism via trait objects.
If `t` is of type `T`, which implements trait `I`,
one can pack the methods of `T` that implements `I`, together with `t`,
into a runtime object via `t as I`.
Trait object erases the concrete type of a value,
so objects created from different concrete types can be put in the same data structure and handled uniformly:

```rust live
trait Animal {
  speak(Self)
}

type Duck String
fn Duck::make(name: String) -> Duck { Duck(name) }
fn speak(self: Duck) -> Unit {
  println(self.0 + ": quak!")
}

type Fox String
fn Fox::make(name: String) -> Fox { Fox(name) }
fn Fox::speak(_self: Fox) -> Unit {
  println("What does the fox say?")
}

fn init {
  let duck1 = Duck::make("duck1")
  let duck2 = Duck::make("duck2")
  let fox1 = Fox::make("fox1")
  let animals = [ duck1 as Animal, duck2 as Animal, fox1 as Animal ]
  let mut i = 0
  while i < animals.length() {
    animals[i].speak()
    i = i + 1
  }
}
```

Not all traits can be used to create objects.
"object-safe" traits' methods must satisfy the following conditions:

- `Self` must be the first parameter of a method
- There must be only one occurrence of `Self` in the type of the method (i.e. the first parameter)

## The question operator
MoonBit features a convenient `?` operator for error handling.
The `?` postfix operator can be applied to expressions of type `Option` or `Result`.
When applied to expression `t : Option[T]`, `t?` is equivalent to:

```rust
match t {
  None => { return None }
  Some(x) => x
}
```

When applied to expression `t: Result[T, E]`, `t?` is equivalent to:

```rust
match t {
  Err(err) => { return Err(err) }
  Ok(x) => x
}
```

The question operator can be used to combine codes that may fail or error elegantly:

```rust
fn may_fail() -> Option[Int] { ... }

fn f() -> Option[Int] {
  let x = may_fail()?
  let y = may_fail()?.lsr(1) + 1
  if y == 0 { return None }
  Some(x / y)
}

fn may_error() -> Result[Int, String] { ... }

fn g() -> Result[Int, String] {
  let x = may_error()?
  let y = may_error()? * 2
  if y == 0 { return Err("divide by zero") }
  Ok(x / y)
}
```

## Test Blocks
MoonBit provides the test code block for writing test cases. For example:

```rust
test "test_name" {
  assert_eq(1 + 1, 2)?
  assert_eq(2 + 2, 4)?
}
```

A test code block is essentially a function that returns a `Result[Unit, String]` type. It is called during the execution of `moon test` and outputs a test report through the build system. The `assert_eq` function is from the standard library; if the assertion fails, it prints an error message and terminates the test. The string "test_name" is used to identify the test case and is optional. If it starts with "panic," it indicates that the expected behavior of the test is to trigger a panic, and the test will only pass if the panic is triggered. For example:

```rust
test "panic_test" {
  let _ : Int = Option::None.unwrap()
}
```

## MoonBit's build system

The introduction to the build system is available at [MoonBit's Build System Tutorial](./build-system-tutorial.md).
