# MoonBit for Go Programmers

MoonBit is a modern programming language designed for cloud and edge computing.
If you're coming from Go, you'll find some familiar concepts alongside powerful
new features that make MoonBit a simple yet expressive and performant language.

## Key Similarities

Both Go and MoonBit are:

- **Statically typed** with type inference
- **Compiled languages** with fast compilation
- **Memory safe**, though through slightly different mechanisms
- **Designed for modern computing** with excellent tooling

## Major Differences at a Glance

| Aspect                | Go                                          | MoonBit                                                  |
|-----------------------|---------------------------------------------|----------------------------------------------------------|
| **Paradigm**          | Imperative with certain functional features | Both functional and imperative                           |
| **Memory Management** | Garbage collected                           | Reference counting/GC (backend dependent)                |
| **Error Handling**    | Multiple return values                      | Checked error-throwing functions                         |
| **Generics**          | Interfaces and type parameters              | Full generic system with traits (similar to Rust)        |
| **Pattern Matching**  | Limited (`switch` statements)               | Comprehensive pattern matching                           |
| **Target Platforms**  | Native binaries                             | WebAssembly, JavaScript, native binaries (via C or LLVM) |

## Identifiers and Naming Conventions

In Go, identifiers are case-sensitive and must start with a Unicode letter
or an underscore, followed by any number of Unicode letters, Unicode digits,
or underscores.

Since the first letter of a Go identifier dictates its visibility
(uppercase for public, lowercase for private), the convention is to use
camelCase for private items, and PascalCase for public ones:

```go
type privateType int
var PublicVariable PublicType = PublicFunction()
privateVariable := privateFunction()
```

In MoonBit, identifiers are also case-sensitive and follow a very similar
set of rules as Go, but the casing of the initial letter has no effect on
visibility. Instead, lowercase initial letters should be used for
variables and functions, while uppercase ones are reserved for types,
traits, enumeration variants, etc.

As a result, the MoonBit convention is to use snake_case for the former
category, and CamelCase for the latter:

```moonbit
Enumeration::Variant(random_variable).do_something()
impl[T : Trait] for Structure[T] with some_method(self, other) { ... }
```

## Variable Bindings

In Go, new bindings are created using `var` or `:=`.
Type inference is activated by the `:=` syntax or the omission of type
annotation when using `var`.
There is no way to mark a variable as immutable.

```go
var name string = "MoonBit"
var count = 25 // Or `count := 25`
// There are no immutable variables in Go
```

In MoonBit, new bindings are created with the `let` keyword.
They are immutable by default, and you can use `let mut` to create mutable ones.
Types can be optionally specified with `:` after the variable name, and type
inference is used in the absent case.

```moonbit
let mut name : String = "MoonBit"
let mut count = 25
let pi = 3.14159 // Omit `mut` to create an immutable binding
```

Note `mut` is only allowed in local bindings, and not allowed in global bindings.

## Newtypes

Newtypes are used to create type-safe wrappers around existing types,
so that you can define domain-specific types with the same underlying
representation as the original type, but with a different set of
available operations.

In Go, newtypes can be created using the `type` keyword.
A round trip from the underlying value to the newtype-wrapped one is
possible via the `T()` conversion syntax:

```go
type Age int

age := Age(25)
ageInt := int(age)
```

Newtypes are defined the same way in MoonBit, but getting the underlying
value requires slightly different syntax:

```moonbit
type Age Int

let age = Age(25)
let age_int = age.inner()
```

## Type Aliases

Type aliases can be created using the `type ... = ...` syntax in Go:

```go
type Description = string
```

In MoonBit, the `typealias` keyword is used instead:

```moonbit
typealias String as Description
```

## Structures

In Go, named structures are newtypes of anonymous structures `struct { ... }`,
hence the common `type ... struct { ... }` idiom:

```go
type Person struct {
    Name string
    Age  int
}
```

The `Person` structure can be created using literals like so:

```go
john := Person{
    Name: "John Doe",
    Age:  30,
}

// Field names can be omitted if the field order is respected:
alice := Person{"Alice Smith", 25}
```

In MoonBit, all structures must be named, and they are defined
using the `struct` keyword:

```moonbit
struct Person {
  name : String
  age : Int
}
```

The `Person` structure can be created using literals like so:

```moonbit
let john = Person::{ name: "John Doe", age: 30 }

// Type name can be omitted if the type can be inferred:
let alice : Person = { name: "Alice Smith", age: 25 }
```

## Enumerations

Enumerations allow you to define a type with a fixed set of values.

In Go, enumeration is not a language feature, but rather an idiom
of using `iota` to create a sequence of constants:

```go
type Ordering int
const (
    Less Ordering = iota
    Equal
    Greater
)
```

On the other hand, MoonBit has a built-in `enum` keyword for defining
enumerations:

```moonbit
enum Ordering {
  Less
  Equal
  Greater
}
```

In addition, MoonBit's enumerations can also have payloads:

```moonbit
enum IntList {
  /// `Nil` represents an empty list and has no payload.
  Nil
  /// `Cons` represents a non-empty list and has two payloads:
  /// 1. The first element of the list;
  /// 2. The remaining parts of the list.
  Cons(Int, IntList)
}
```

## Control Flow

One of MoonBit's key differences from Go is that lots of control structures have
actual return values instead of simply being statements that execute code.
This expression-centered approach allows for more concise and functional programming
patterns compared to Go's statement-based control flow.

### `if` Expressions

In Go, `if` statements don't return values. As a result, you often need to write:

```go
var result string
if condition {
    result = "true case"
} else {
    result = "false case"
}
```

In MoonBit, `if` is an expression that returns a value:

```moonbit
let result = if condition {
  "true case"
} else {
  "false case"
}
```

### `match` Expressions

In Go, `switch` statements can be used to match against values, but they don't
return values directly:

```go
var description string
switch err {
case nil:
    description = fmt.Sprintf("Success: %v", value)
default:
    description = fmt.Sprintf("Error: %s", err)
}
```

On the other hand, `match` expressions in MoonBit can actually return values:

```moonbit
let description = match status {
  Ok(value) => "Success: \{value}"
  Err(error) => "Error: \{error}"
}
```

For more details on `match` expressions, please refer to [Pattern Matching]().

### `loop` Expressions

MoonBit's loops can return values as well.

Functional loops using the `loop` keyword are particularly powerful.
The loop body is similar to that of a `match` expression, where each arm tries to
match the loop variables and act on them accordingly.
You may use the `continue` keyword to start the next iteration of the loop with the given
loop values, or use the `break` keyword to exit the loop with some given output value.
At the trailing expression of each arm, the `break`ing is implicit and thus not required.

```moonbit
// Calculates the sum of all elements in an `xs : IntList`.
let sum = loop (xs, 0) {
  (Nil, acc) => acc
  (Cons(x, rest), acc) => continue (rest, x + acc)
}
```

### `for` and `while` Expressions

MoonBit's `for` and `while` loops are also expressions that return values.

The `for` loop is similar to Go's `for` loop, with a variable initialization, condition, and update
clause respectively:

```moonbit
// Iterates from 1 to 6, summing even numbers.
let sum = for i = 1, acc = 0; i <= 6; i = i + 1 {
  if i % 2 == 0 {
    continue i + 1, acc + i
  }
} else {
  acc
}
```

There are a few distinct features of the `for` loop in MoonBit, however:

- The update clause is not in-place, but rather are used to assign new values to the loop variables.
- `continue` can (optionally) be used to start the next iteration with new input values.
  In that case, the update clause is skipped.
- The `else` clause is used to return the final value of the loop when it normally exits. If the loop
  is exited early with the `break` keyword, the value from the `break` clause is returned instead.

The `while` loop is equivalent to the `for` loop with a condition clause only, and it can also return
a value:

```moonbit
let result = while condition {
  // loop body
  if should_break {
    break "early exit value"
  }
} else {
  "normal completion value"
}
```

## Generic Types

In Go, you can define a generic named structure using type parameters delimited
by square brackets `[]`:

```go
type ListNode[T any] struct {
    val  T
    next *ListNode[T]
}
```

In MoonBit, you would define a generic structure very similarly:

```moonbit
struct ListNode[T] {
  val : T
  next : ListNode[T]?
}
```

In addition, you can also define a generic MoonBit enumeration.
Below are two common generic enumerations available in MoonBit's standard library:

```moonbit
enum Option[T] {
  None
  Some(T)
}

enum Result[T, E] {
  Ok(T)
  Err(E)
}
```

## Functions

In Go, functions are defined using the `func` keyword followed by
the function name, parameters, and return type.

```go
func add(a int, b int) int {
    return a + b
}
```

In MoonBit, function definitions use the `fn` keyword and a
slightly different syntax:

```moonbit
fn add(a : Int, b : Int) -> Int {
  a + b
}
```

Note the use of the `:` token to specify types, and the `->` token
to indicate the return type.
Also, the function body is an expression that returns a value, so the
`return` keyword is not required unless early exits are needed.

### Value and Reference Semantics

Understanding how data is passed and stored is crucial when moving between programming languages.
Go and MoonBit, in particular, have different approaches to value and reference semantics.

In Go, **the value semantics is the default**.
That is, values are copied when passed to functions or assigned to variables:

```go
type Point struct {
    X int
    Y int
}

func modifyPointVal(p Point) {
    p.X = 100  // This modifies a copy, not the original
}

func main() {
    point := Point{X: 10, Y: 20}
    modifyPointVal(point)
    fmt.Println(point.X) // Still prints 10, not 100
}
```

To achieve **reference semantics** in Go, you often need to explicitly
create and dereference pointers:

```go
func modifyPointRef(p *Point) {
    p.X = 100  // This modifies the original through the pointer
}

func main() {
    point := Point{X: 10, Y: 20}
    modifyPointRef(&point)  // Create a pointer with the `&` operator
    fmt.Println(point.X)    // Now prints 100
}
```

Some other built-in types like slices and maps behave similarly to pointers in Go,
but all these types are still technically passed by value (the value being a reference):

```go
func incrementSlice(nums []int) {
    for i := range nums {
        nums[i]++  // Modifies original slice
    }
}

func modifyMap(m map[string]int) {
    m["key"] = 42  // Modifies original map
}
```

MoonBit is semantically *always passed by reference*.
But for immutable types and primitive types, they may be passed by value since
this is semantically the same, this is purely an optimization.

<!-- MoonBit does not have pointer types, and which semantic is used when passing a value
depends on its type: a value of an \*\*immutable type\*\* is passed by value, while that
of a \*\*mutable type\*\* is passed by reference. -->

Notable **primitive types** in MoonBit include
[`Unit`](../../language/fundamentals.md#unit)
, [`Boolean`](../../language/fundamentals.md#boolean)
, integers ([`Int`](../../language/fundamentals.md#number), [`Int64`](../../language/fundamentals.md#number), [`UInt`](../../language/fundamentals.md#number), etc.)
, floating-point numbers ([`Double`](../../language/fundamentals.md#number), [`Float`](../../language/fundamentals.md#number), etc.)
, [`String`](../../language/fundamentals.md#string)
, [`Char`](../../language/fundamentals.md#char)
, [`Byte`](../../language/fundamentals.md#byte-s).

Notable **immutable collection types** in MoonBit include
[tuples](../../language/fundamentals.md#tuple),
immutable collections such as `@immut/hashset.T[A]`,
and custom types with no `mut` fields.

On the other hand, notable **mutable collection types** include
mutable collections such as [`Array[T]`](../../language/fundamentals.md#array)
, [`FixedArray[T]`](../../language/fundamentals.md#array)
, and [`Map[K, V]`](../../language/fundamentals.md#map),
as well as custom types with at least one `mut` field.

For example, we can rewrite some of the above Go examples in MoonBit:

```moonbit
struct Point {
  mut x : Int
  mut y : Int
}

fn modify_point_ref(p : Point) -> Unit {
  p.x = 100 // Modifies the original struct
}

fn main {
  let point = Point::{ x: 10, y: 20 }
  modify_point_ref(point) // Passes the original struct by reference
  println("\{point.x}")   // Prints 100
}

fn increment_array(nums : Array[Int]) -> Unit {
  for i = 0; i < nums.length(); i = i + 1 {
    nums[i] += 1 // Modifies the original array
  }
}

fn modify_map(m : Map[String, Int]) -> Unit {
  m["key"] = 42 // Modifies the original map
}
```

#### The [`Ref[T]`](../../language/fundamentals.md#ref) Helper Type

When you need explicit mutable references to value types,
MoonBit provides the [`Ref[T]`](../../language/fundamentals.md#ref) type
which is roughly defined as follows:

```moonbit
struct Ref[T] {
  mut val : T
}
```

With the help of `Ref[T]`, you can create mutable references to a value
just like you would with pointers in Go:

```moonbit
fn increment_counter(counter : Ref[Int]) -> Unit {
  counter.val = counter.val + 1
}

fn main {
  let counter = Ref::new(0)
  increment_counter(counter)
  println(counter.val) // Prints 1
}
```

### Generic Functions

In Go, you can define a generic function using type parameters:

```go
// `T` is a type parameter that must implement the `fmt.Stringer` interface.
func DoubleString[T fmt.Stringer](t T) string {
    s := t.String()
    return s + s
}
```

The same is true for MoonBit:

```moonbit
// `T` is a type parameter that must implement the `Show` trait.
fn[T : Show] double_string(t : T) -> String {
  let s = t.to_string()
  s + s
}
```

### Named Parameters

MoonBit functions also support named arguments with an optional
default value using the `label~ : Type` syntax:

```moonbit
fn named_args(named~ : Int, optional~ : Int = 42) -> Int {
  named + optional
}

// This can be called like so:
named_args(named=10)               // optional defaults to 42
named_args(named=10, optional=20)  // optional is set to 20
named_args(optional=20, named=10)  // order doesn't matter
let named = 10
named_args(named~)                 // `label~` is a shorthand for `label=label`
```

### Optional Return Values

For functions that may or may not logically return a value of type `T`,
Go encourages the use of multiple return values:

In particular, `(res T, ok bool)` is used to indicate an optional return value:

```go
func maybeDivide(a int, b int) (quotient int, ok bool) {
    if b == 0 {
        return 0, false
    }
    return a / b, true
}
```

In MoonBit, to return an optional value, you will simply need to return `T?`
(shorthand for `Option[T]`):

```moonbit
fn maybe_divide(a : Int, b : Int) -> Int? {
  if b == 0 {
    None
  } else {
    Some(a / b)
  }
}
```

### Fallible Functions

For functions that may return an error, Go uses `(res T, err error)` at the return position:

```go
func divide(a int, b int) (quotient int, err error) {
    if b == 0 {
        return 0, errors.New("division by zero")
    }
    return a / b, nil
}
```

You can then use the above `divide` function with the common `if err != nil` idiom:

```go
func useDivide() error {
    q, err := divide(10, 2)
    if err != nil {
        return err
    }
    fmt.Println(q) // Use the quotient
    return nil
}
```

In MoonBit, fallible functions are declared a bit differently. To indicate that
the function might throw an error, write `T raise E` at the return type
position, where `E` is an error type declared with `suberror`:

```moonbit
suberror ValueError String

fn divide(a : Int, b : Int) -> Int raise ValueError {
  if b == 0 {
    raise ValueError("division by zero")
  }
  a / b
}
```

There are different ways to handle the error when calling such a throwing function:

```moonbit
// Option 1: Propagate the error directly.
fn use_divide_propagate() -> Unit raise ValueError {
  let q = divide(10, 2) // Rethrow the error if it occurs
  println(q) // Use the quotient
}

// Option 2: Use `try?` to convert the error to a `Result[T, E]` type.
fn use_divide_try() -> Unit raise ValueError {
  // The type annotation is optional
  let mq : Result[
    Int,
    ValueError,
  ] = try? divide(10, 2)
  match mq { // Refer to the section on pattern matching for more details
    Err(e) => raise e
    Ok(q) => println(q) // Use the quotient
  }
}

// Option 3: Use the `try { .. } catch { .. }` syntax to handle the error.
fn use_divide_try_catch() -> Unit raise ValueError {
  try {
    let q = divide(10, 2)
    println(q) // Use the quotient
  } catch {
    e => raise e
  }
}
```

## Pattern Matching

Go has no builtin support for pattern matching.
In certain cases, you can use the `switch` statement to achieve similar functionality:

```go
func fibonacci(n int) int {
    switch n {
    case 0:
        return 0
    case 1, 2:
        return 1
    default:
        return fibonacci(n-1) + fibonacci(n-2)
    }
}
```

MoonBit, on the other hand, offers comprehensive pattern matching with the `match` keyword.

You can match against literal values such as booleans, integers, strings, etc.:

```moonbit
fn fibonacci(n : Int) -> Int {
  match n {
    0 => 0
    // `|` combines multiple patterns
    1 | 2 => 1
    // `_` is a wildcard pattern that matches anything
    _ => fibonacci(n - 1) + fibonacci(n - 2)
  }
}
```

In addition, it is possible to perform destructuring of structures and tuples:

```moonbit
struct Point3D {
  x : Int
  y : Int
  z : Int
}

fn use_point3d(p : Point3D) -> Unit {
  match p {
    { x: 0, .. } => println("x == 0")
    // The `if` guard allows you to add additional conditions
    // for this arm to match.
    { y, z, .. } if y == z => println("x != 0, y == z")
    _ => println("uncategorized")
  }
}
```

Finally, array patterns allow you to easily destructure arrays, bytes, strings, and views:

```moonbit
fn categorize_array(array : Array[Int]) -> String {
  match array {
    [] => "empty"
    [x] => "only=\{x}"
    [first, .. middle, last] =>
      "first=\{first} and last=\{last} with middle=\{middle}"
  }
}

fn is_palindrome(s : @string.View) -> Bool {
  match s {
    [] | [_] => true
    // `a` and `b` capture the first and last characters of the view, and
    // `.. rest` captures the middle part of the view as a new view.
    [a, .. rest, b] if a == b => is_palindrome(rest)
    _ => false
  }
}
```

## Methods and Traits

Although both languages support methods and behavior sharing via traits/interfaces,
MoonBit's approach to methods and traits/interfaces differs significantly from Go's.

As we will see below, MoonBit allows for more flexibility and expressiveness in terms of
trait methods than go, since in MoonBit:

- A trait must be explicitly implemented for each type;
- A type's method is not necessarily object-safe (i.e. can be used in trait objects),
  in fact, they don't even need to have `self` as the first parameter at all.

### Methods

In Go, methods are defined on types using the receiver syntax:

```go
type Rectangle struct {
    width, height float64
}

func (r *Rectangle) Area() float64 {
    return r.width * r.height
}

func (r *Rectangle) Scale(factor float64) {
    r.width *= factor
    r.height *= factor
}
```

Methods can be called using the `.method()` syntax:

```go
rect := Rectangle{width: 10.0, height: 5.0}
areaValue := rect.Area()
rect.Scale(2.0) // NOTE: `.Scale()` modifies the rectangle in place.
```

In MoonBit, however, a type `T`'s methods are simply functions defined with the
`T::` prefix.

This is how you would recreate the above `Rectangle` example in MoonBit:

```moonbit
struct Rectangle {
  // `mut` allows these fields to be modified in-place.
  mut width : Double
  mut height : Double
}

fn Rectangle::area(self : Rectangle) -> Double {
  self.width * self.height
}

fn Rectangle::scale(self : Rectangle, factor : Double) -> Unit {
  // NOTE: `self` have reference semantics here, since `Rectangle` is mutable.
  self.width *= factor
  self.height *= factor
}
```

... and you can call methods like this:

```moonbit
let rect = Rectangle::{ width: 10.0, height: 5.0 }
let area_value = rect.area()
rect.scale(2.0) // NOTE: `.scale()` modifies the rectangle in place.
```

### Traits

Go uses interfaces for polymorphism:

```go
type Shape interface {
    Area() float64
    Perimeter() float64
}

// Implicitly implements the `Shape` interface for `Rectangle`
// `func (r *Rectangle) Area() float64` already exists
func (r *Rectangle) Perimeter() float64 {
    return 2 * (r.width + r.height)
}

// Static dispatch is possible using generic functions with type bounds
func PrintShapeInfo[T Shape](s T) {
    fmt.Printf("Area: %f, Perimeter: %f\n", s.Area(), s.Perimeter())
}

// Dynamic dispatch is possible using the interface type
func PrintShapeInfoDyn(s Shape) {
    PrintShapeInfo(s)
}

func TestRectangle(t *testing.T) {
    rect := &Rectangle{10, 5}
    PrintShapeInfo(rect)
    PrintShapeInfoDyn(rect)
}
```

MoonBit has traits, which are similar to Go interfaces:

```moonbit
trait Shape {
  area(Self) -> Double
  perimeter(Self) -> Double
}

// Explicitly implement the `Shape` trait for `Rectangle`
impl Shape for Rectangle with area(self) {
  // NOTE: This is a method call to the previously-defined `Rectangle::area()`,
  // thus no recursion is involved.
  self.area()
}

impl Shape for Rectangle with perimeter(self) {
  2.0 * (self.width + self.height)
}

// Static dispatch is possible using generic functions with type bounds
fn[T : Shape] print_shape_info(shape : T) -> Unit {
  println("Area: \{shape.area()}, Perimeter: \{shape.perimeter()}")
}

// Dynamic dispatch is possible using the `&Shape` trait object type
fn print_shape_info_dyn(shape : &Shape) -> Unit {
  print_shape_info(shape)
}

test {
  let rect = Rectangle::{ width: 10.0, height: 5.0 }
  print_shape_info(rect)
  print_shape_info_dyn(rect)
}
```

### Object Safety

MoonBit traits can also include certain kinds of methods not available in Go interfaces,
such as the ones with no `self` parameter, as shown in the example below:

```moonbit
trait Name {
  name() -> String
}

impl Name for Rectangle with name() {
  "Rectangle"
}

// `T : Shape + Name` is a bound that requires the type `T` to
// implement both `Shape` and `Name`.
fn[T : Shape + Name] print_shape_name_and_info(shape : T) -> Unit {
  println(
    "\{T::name()}, Area: \{shape.area()}, Perimeter: \{shape.perimeter()}",
  )
}

test {
  print_shape_name_and_info(Rectangle::{ width: 10.0, height: 5.0 })
}
```

However, for a trait to be usable in a trait object, it must only contain object-safe methods.

There are a few requirements for a method of type `T` to be object-safe:

- `self : T` should be the first parameter of the method;
- Any other parameter of the method should not have the type `T`.

For example, in the above `Name` trait, the `name()` method is not object-safe because it does not
have a `self` parameter, and thus `Name` cannot be used in the hypothetical `&Name` trait object.

### Trait Extensions

MoonBit traits can explicitly extend other traits, allowing you to build on existing functionality:

```moonbit
pub(open) trait Position {
  pos(Self) -> (Int, Int)
}

pub(open) trait Draw {
  draw(Self, Int, Int) -> Unit
}

pub(open) trait Object: Position + Draw {
  // You can add more required methods here...
}
```

Since the `Object` trait extends two traits `Position` and `Draw`, the latter two are called the
former's **supertrait**s.

### Default Implementations

Unlike Go interfaces, MoonBit trait functions can have default implementations:

```moonbit
trait Printable {
  print(Self) -> Unit
  // `= _` marks the method as having a default implementation
  print_twice(Self) -> Unit = _
}

// The default implementation of `print_twice()` is provided individually:
impl Printable with print_twice(self) {
  self.print()
  self.print()
}
```

### Operator Overloading

MoonBit supports operator overloading through built-in traits, which has no Go equivalent:

```moonbit
impl Add for Rectangle with op_add(self, other) {
  { width: self.width + other.width, height: self.height + other.height }
}

// Now you can use + with rectangles
let combined = rect1 + rect2
```

## Imports and Package Management

Package management and imports work differently between Go and MoonBit.

### Creating a Project

In Go, the first thing to do when creating a new project is running:

```console
$ go mod init example.com/my-project
```

This will initialize a `go.mod` file that tracks your project's dependencies.

Then you can create a `main.go` file with the `package main` declaration and
start writing your code:

```go
package main

import "fmt"

func main() { fmt.Println("Hello, 世界") }
```

In MoonBit, creating a new project is much easier. Simply run the `moon new`
command to set up your project:

```console
$ moon new my-project
```

### Project Structure

The Go toolchain has few requirements for the project structure, apart
from the `go.mod` file being in the root directory of the project.
To scale up from a single `main.go` file to a larger project, you would
typically add more files and directories, resulting in a flat or nested
structure, depending on the style you choose.

While organizing the source files, the key point is that Go's tooling
doesn't distinguish between source files under a common directory, so you
can freely create multiple `.go` files in the same package directory, knowing
that they will be treated as a whole by the toolchain.
For definitions within source files of another directory, however,
you would need to import them before they can be used.

In MoonBit, on the other hand, the default project structure provided by
`moon new` is more organized, as shown below:

```txt
my-project
├── LICENSE
├── README.md
├── moon.mod.json
└── src
    ├── lib
    │   ├── hello.mbt
    │   ├── hello_test.mbt
    │   └── moon.pkg.json
    └── main
        ├── main.mbt
        └── moon.pkg.json
```

This demonstrates a typical "binary-and-library" project structure in MoonBit,
located in the `src` directory. This is declared in `moon.mod.json` like so
(with irrelevant parts omitted):

```json
{
  "source": "src"
}
```

This is the module configuration file that also registers the project's
basic information such as its name, version, and dependencies.

Each directory under the source directory (`src` in this example) is a package
with its own `moon.pkg.json` file containing package-specific metadata,
such as its imports, and whether it should be regarded as a main binary package.
For example, `src/lib/moon.pkg.json` is minimally defined as follows:

```json
{}
```

... and `src/main/moon.pkg.json` as follows:

```json
{
  "is_main": true,
  "import": ["username/hello/lib"]
}
```

Similarly to Go, MoonBit treats all `.mbt` files under a same package directory
as a whole. When creating a new directory for more source files, however,
a corresponding `moon.pkg.json` file is required under that directory.

### Running the Project

To run the aforementioned Go project, you would typically use:

```console
$ go run main.go
```

Running the previous MoonBit project with `moon run` is very similar:

```console
$ moon run src/main/main.mbt
```

### Adding Imports

In Go, you can add imports with the `import` clause followed by their module path:

```go
package main

import (
    "github.com/user/repo/sys"
)
```

MoonBit uses a different approach with `moon.mod.json` for module configuration and
`moon.pkg.json` for package configuration.

First, declare dependencies in the `"deps"` section of your `moon.mod.json`.
This is usually done with the `moon add <package>` command.

For example, to use `moonbitlang/x`, you would run:

```console
$ moon add moonbitlang/x
```

... which would result in a `moon.mod.json` file like so (with irrelevant parts omitted):

```json
{
  "deps": {
    "moonbitlang/x": "*"
  }
}
```

Then, in your package's `moon.pkg.json`, specify which packages to import
in the `"import"` section:

```json
{
  "import": ["moonbitlang/x/sys"]
}
```

Now you should be ready to use the `sys` package in this MoonBit package.

### Using Imported Packages

In Go, the above import allows you to access the `sys` package's APIs
using the `<package-name>.` prefix (the actual API is hypothetical):

```go
func main() {
    sys.SetEnvVar("MOONBIT", "Hello")
}
```

In MoonBit, you access imported APIs using the `@<package-name>.` prefix:

```moonbit
fn main {
  @sys.set_env_var("MOONBIT", "Hello")
}
```

### Package Aliases

In Go, you can create aliases for imported packages using the `import` statement:

```go
import (
    system "github.com/user/repo/sys"
)
```

In MoonBit, you can create aliases for imported packages in `moon.pkg.json` using the `alias` field:

```json
{
  "import": [
    {
      "path": "moonbitlang/x/sys"
      "alias": "system"
    }
  ]
}
```

Then you may use the alias like so:

```moonbit
fn main {
  @system.set_env_var("MOONBIT", "Hello")
}
```

### Access Control

In Go, visibility is determined by the case of the first letter of an identifier
(uppercase for public, lowercase for private).

MoonBit has more granular access control than Go, providing the following visibility levels:

- `priv`: Completely private (like Go's lowercase identifiers)
- Default (abstract): Only the type name is visible, implementation is hidden
- `pub`: Read-only access from outside the package
- `pub(all)`: Full public access (like Go's uppercase identifiers)

This gives you fine-grained control over what parts of your API are exposed and how they can be used.

## Runtime Support

The same MoonBit code can target multiple runtimes with different code generation
backends, allowing you to choose the best fit for your particular application:

- WebAssembly (for web and edge computing)
- JavaScript (for Node.js integration)
- C (for native performance)
- LLVM (experimental)

### Memory Management

Go uses a garbage collector, while MoonBit uses different strategies depending on the
code generation backend being used:

- **Wasm/C backends**: Reference counting without cycle detection
- **Wasm GC/JavaScript backends**: Leverages the runtime's garbage collector

## Getting Started

1. Visit [the online playground](https://try.moonbitlang.com).
2. Check out our [installation guide](../tour.md#installation).
3. Create your first MoonBit project:
   ```console
   $ moon new hello-world
   $ cd hello-world
   $ moon run
   ```

## When to Choose MoonBit

MoonBit offers a fresh take on systems programming with functional programming benefits and WebAssembly-first design.
While different from Go's philosophy, it provides powerful tools for building efficient, safe, and maintainable applications.
Thus, MoonBit will be an interesting option for your project if you embrace:

- **WebAssembly targets** with minimal size and maximum performance
- **Functional programming** features like pattern matching and algebraic data types
- **Mathematical/algorithmic code** that benefits from immutability by default
- **Strong type safety** with comprehensive error handling

## Next Steps

- Explore the [Language Fundamentals](../../language/fundamentals.md)
- Learn about [Error Handling](../../language/error-handling.md)
- Understand [Methods and Traits](../../language/methods.md)
- Check out [FFI capabilities](../../language/ffi.md) for interop
