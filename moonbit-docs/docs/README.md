# MoonBit

MoonBit is an end-to-end programming language toolchain for cloud and edge computing using WebAssembly. The IDE environment is available at [https://try.moonbitlang.com](https://try.moonbitlang.com) without any installation; it does not rely on any server either.

## Status and aimed timeline

MoonBit is currently in beta-preview. We expect to reach beta in 2024/11/22, and 1.0 in 2025.

When MoonBit reaches beta, it means any backwards-incompatible changes will be seriously evaluated and MoonBit _can_ be used in production(very rare compiler bugs). MoonBit is developed by a talented full time team who had extensive experience in building language toolchains, so we will grow much faster than the typical language ecosystem, you won't wait long to use MoonBit in your production.

## Main advantages

- Generate significantly smaller WASM output than any existing solutions.
- Much faster runtime performance.
- State of the art compile-time performance.
- Simple but practical, data-oriented language design.

## Overview

A MoonBit program consists of type definitions, function definitions, and variable bindings.

### Program entrance

There is a specialized function called `init` function. The `init` function is special in two aspects:

1. There can be multiple `init` functions in the same package.
2. An `init` function can't be explicitly called or referred to by other functions. Instead, all `init` functions will be implicitly called when initializing a package. Therefore, `init` functions should only consist of statements.

```moonbit live
fn main {
  let x = 1
  // x // fail
  println(x) // success
}
```

For WebAssembly backend, it means that it will be executed **before** the instance is available, meaning that the FFIs that relies on the instance's exportations can not be used at this stage;
for JavaScript backend, it means that it will be executed during the importation stage.

There is another specialized function called `main` function. The `main` function is the main entrance of the program, and it will be executed after the initialization stage.
Only packages that are `main` packages can define such `main` function. Check out [build system tutorial](https://moonbitlang.github.io/moon/) for detail.

The two functions above need to drop the parameter list and the return type.

### Expressions and Statements

MoonBit distinguishes between statements and expressions. In a function body, only the last clause should be an expression, which serves as a return value. For example:

```moonbit
fn foo() -> Int {
  let x = 1
  x + 1 // OK
}

fn bar() -> Int {
  let x = 1
  x + 1 // fail
  x + 2
}
```

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
- `return` statements
- Any expression whose return type is `unit`

## Functions

Functions take arguments and produce a result. In MoonBit, functions are first-class, which means that functions can be arguments or return values of other functions. MoonBit's naming convention requires that function names should not begin with uppercase letters (A-Z). Compare for constructors in the `enum` section below.

### Top-Level Functions

Functions can be defined as top-level or local. We can use the `fn` keyword to define a top-level function that sums three integers and returns the result, as follows:

```moonbit
fn add3(x: Int, y: Int, z: Int)-> Int {
  x + y + z
}
```

Note that the arguments and return value of top-level functions require explicit type annotations.

### Local Functions

Local functions can be named or anonymous. Type annotations can be omitted for local function definitions: they can be automatically inferred in most cases. For example:

```moonbit live
fn foo() -> Int {
  fn inc(x) { x + 1 }  // named as `inc`
  fn (x) { x + inc(2) } (6) // anonymous, instantly applied to integer literal 6
}

fn main {
  println(foo())
}
```

Functions, whether named or anonymous, are _lexical closures_: any identifiers without a local binding must refer to bindings from a surrounding lexical scope. For example:

```moonbit live
let y = 3
fn foo(x: Int) -> Unit {
  fn inc()  { x + 1 } // OK, will return x + 1
  fn four() { y + 1 } // Ok, will return 4
  println(inc())
  println(four())
}

fn main {
  foo(2)
}
```

### Function Applications

A function can be applied to a list of arguments in parentheses:

```moonbit
add3(1, 2, 7)
```

This works whether `add3` is a function defined with a name (as in the previous example), or a variable bound to a function value, as shown below:

```moonbit live
fn main {
  let add3 = fn(x, y, z) { x + y + z }
  println(add3(1, 2, 7))
}
```

The expression `add3(1, 2, 7)` returns `10`. Any expression that evaluates to a function value is applicable:

```moonbit live
fn main {
  let f = fn (x) { x + 1 }
  let g = fn (x) { x + 2 }
  println((if true { f } else { g })(3)) // OK
}
```

### Labelled arguments

Functions can declare labelled argument with the syntax `~label : Type`. `label` will also serve as parameter name inside function body:

```moonbit
fn labelled(~arg1 : Int, ~arg2 : Int) -> Int {
  arg1 + arg2
}
```

Labelled arguments can be supplied via the syntax `label=arg`. `label=label` can be abbreviated as `~label`:

```moonbit
fn init {
  let arg1 = 1
  println(labelled(arg2=2, ~arg1)) // 3
}
```

Labelled function can be supplied in any order. The evaluation order of arguments is the same as the order of parameters in function declaration.

### Optional arguments

A labelled argument can be made optional by supplying a default expression with the syntax `~label : Type = default_expr`. If this argument is not supplied at call site, the default expression will be used:

```moonbit live
fn optional(~opt : Int = 42) -> Int {
  opt
}

fn main {
  println(optional()) // 42
  println(optional(opt=0)) // 0
}
```

The default expression will be evaluated every time it is used. And the side effect in the default expression, if any, will also be triggered. For example:

```moonbit live
fn incr(~counter : Ref[Int] = { val: 0 }) -> Ref[Int] {
  counter.val = counter.val + 1
  counter
}

fn main {
  println(incr()) // 1
  println(incr()) // still 1, since a new reference is created every time default expression is used
  let counter : Ref[Int] = { val: 0 }
  println(incr(~counter)) // 1
  println(incr(~counter)) // 2, since the same counter is used
}
```

If you want to share the result of default expression between different function calls, you can lift the default expression to a toplevel `let` declaration:

```moonbit live
let default_counter : Ref[Int] = { val: 0 }

fn incr(~counter : Ref[Int] = default_counter) -> Int {
  counter.val = counter.val + 1
  counter.val
}

fn main {
  println(incr()) // 1
  println(incr()) // 2
}
```

Default expression can depend on the value of previous arguments. For example:

```moonbit
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

```moonbit
fn f(_x : Int, _y : Int, ~loc : SourceLoc = _, ~args_loc : ArgsLoc = _) -> Unit {
  println("loc of whole function call: \{loc}")
  println("loc of arguments: \{args_loc}")
}

fn main {
  f(1, 2)
  // loc of whole function call: <filename>:7:3-7:10
  // loc of arguments: [Some(<filename>:7:5-7:6), Some(<filename>:7:8-7:9), None, None]
}
```

Autofill arguments are very useful for writing debugging and testing utilities.

## Control Structures

### Conditional Expressions

A conditional expression consists of a condition, a consequent, and an optional else clause.

```moonbit
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

```moonbit
if x == y {
  expr1
} else if z == k {
  expr2
}
```

Curly brackets are used to group multiple expressions in the consequent or the else clause.

#### Conditional Binding

In MoonBit, as a conditional expression always returns a value, it can be used to bind the value of the condition to a variable.
Here is an example:

```moonbit
let initial = if size < 1 { 1 } else { size }
```

Note that the return values of the consequent and the else clause must be of the same type.

### Guard Statement

The `guard` keyword checks if a specified condition is true. If the condition is met, the program continues execution. If the condition is not met (i.e., `false`), the code within the else block is executed.

```moonbit
guard index >= 0 && index < len else {
  abort("Index out of range")
}
```

### While loop

In MoonBit, `while` loop can be used to execute a block of code repeatedly as long as a condition is true. The condition is evaluated before executing the block of code. The `while` loop is defined using the `while` keyword, followed by a condition and the loop body. The loop body is a sequence of statements. The loop body is executed as long as the condition is true.

```moonbit
let mut i = 5
while i > 0 {
  println(i)
  i = i - 1
}
```

The loop body supports `break` and `continue`. Using `break` allows you to exit the current loop, while using `continue` skips the remaining part of the current iteration and proceeds to the next iteration.

```moonbit live
fn main {
  let mut i = 5
  while i > 0 {
    i = i - 1
    if i == 4 { continue }
    if i == 1 { break }
    println(i)
  }
}
```

The `while` loop also supports an optional `else` clause. When the loop condition becomes false, the `else` clause will be executed, and then the loop will end.

```moonbit live
fn main {
  let mut i = 2
  while i > 0 {
    println(i)
    i = i - 1
  } else {
    println(i)
  }
}
```

When there is an `else` clause, the `while` loop can also return a value. The return value is the evaluation result of the `else` clause. In this case, if you use `break` to exit the loop, you need to provide a return value after `break`, which should be of the same type as the return value of the `else` clause.

```moonbit
  let mut i = 10
  let r1 =
    while i > 0 {
      i = i - 1
      if i % 2 == 0 { break 5 } // break with 5
    } else {
      7
    }
  println(r1) //output: 5
```

```moonbit
  let mut i = 10
  let r2 =
    while i > 0 {
      i = i - 1
    } else {
      7
    }
  println(r2) //output: 7
```

## For Loop

MoonBit also supports C-style For loops. The keyword `for` is followed by variable initialization clauses, loop conditions, and update clauses separated by semicolons. They do not need to be enclosed in parentheses.
For example, the code below creates a new variable binding `i`, which has a scope throughout the entire loop and is immutable. This makes it easier to write clear code and reason about it:

```moonbit
for i = 0; i < 5; i = i + 1 {
  println(i)
}
// output:
// 0
// 1
// 2
```

The variable initialization clause can create multiple bindings:

```moonbit
for i = 0, j = 0; i + j < 100; i = i + 1, j = j + 1 {
  println(i)
}
```

It should be noted that in the update clause, when there are multiple binding variables, the semantics are to update them simultaneously. In other words, in the example above, the update clause does not execute `i = i + 1`, `j = j + 1` sequentially, but rather increments `i` and `j` at the same time. Therefore, when reading the values of the binding variables in the update clause, you will always get the values updated in the previous iteration.

Variable initialization clauses, loop conditions, and update clauses are all optional. For example, the following two are infinite loops:

```moonbit
for i=1;; i=i+1 {
  println(i) // loop forever!
}
```

```moonbit
for {
  println("loop forever!")
}
```

The `for` loop also supports `continue`, `break`, and `else` clauses. Like the `while` loop, the `for` loop can also return a value using the `break` and `else` clauses.

The `continue` statement skips the remaining part of the current iteration of the `for` loop (including the update clause) and proceeds to the next iteration. The `continue` statement can also update the binding variables of the `for` loop, as long as it is followed by expressions that match the number of binding variables, separated by commas.

For example, the following program calculates the sum of even numbers from 1 to 6:

```moonbit live
fn main {
  let sum =
    for i = 1, acc = 0; i <= 6; i = i + 1 {
      if i % 2 == 0 {
        println("even: \{i}")
        continue i + 1, acc + i
      }
    } else {
      acc
    }
  println(sum)
}
```

### `for .. in` loop

MoonBit supports traversing elements of different data structures and sequences via the `for .. in` loop syntax:

```moonbit
for x in [ 1, 2, 3 ] {
  println(x)
}
```

`for .. in` loop is translated to the use of `Iter` in MoonBit's standard library. Any type with a method `.iter() : Iter[T]` can be traversed using `for .. in`.
For more information of the `Iter` type, see [Iterator](#iterator) below.

In addition to sequences of a single value, MoonBit also supports traversing sequences of two values, such as `Map`, via the `Iter2` type in MoonBit's standard library.
Any type with method `.iter2() : Iter2[A, B]` can be traversed using `for .. in` with two loop variables:

```moonbit
for k, v in { "x": 1, "y": 2, "z": 3 } {
  println("\{k} => \{v}")
}
```

Another example of `for .. in` with two loop variables is traversing an array while keeping track of array index:

```moonbit
for index, elem in [ 4, 5, 6 ] {
  let i = index + 1
  println("The \{i}-th element of the array is \{elem}")
}
```

Control flow operations such as `return`, `break` and error handling are supported in the body of `for .. in` loop:

```moonbit
test "map test" {
  let map = { "x": 1, "y": 2, "z": 3 }
  for k, v in map {
    assert_eq!(map[k], Some(v))
  }
}
```

If a loop variable is unused, it can be ignored with `_`.

### Functional loop

Functional loop is a powerful feature in MoonBit that enables you to write loops in a functional style.

A functional loop consumes arguments and returns a value. It is defined using the `loop` keyword, followed by its arguments and the loop body. The loop body is a sequence of clauses, each of which consists of a pattern and an expression. The clause whose pattern matches the input will be executed, and the loop will return the value of the expression. If no pattern matches, the loop will panic. Use the `continue` keyword with arguments to start the next iteration of the loop. Use the `break` keyword with arguments to return a value from the loop. The `break` keyword can be omitted if the value is the last expression in the loop body.

```moonbit live
fn sum(xs: @immut/list.T[Int]) -> Int {
  loop xs, 0 {
    Nil, acc => break acc // break can be omitted
    Cons(x, rest), acc => continue rest, x + acc
  }
}

fn main {
  println(sum(Cons(1, Cons(2, Cons(3, Nil)))))
}
```

## Iterator

An iterator is an object that traverse through a sequence while providing access
to its elements. Traditional OO languages like Java's `Iterator<T>` use `next()`
`hasNext()` to step through the iteration process, whereas functional languages
(JavaScript's `forEach`, Lisp's `mapcar`) provides a high-order function which
takes an operation and a sequence then consumes the sequence with that operation
being applied to the sequence. The former is called _external iterator_ (visible
to user) and the latter is called _internal iterator_ (invisible to user).

The built-in type `Iter[T]` is MoonBit's internal iterator implementation.
Almost all built-in sequential data structures have implemented `Iter`:

```moonbit
fn filter_even(l : Array[Int]) -> Array[Int] {
  let l_iter : Iter[Int] = l.iter()
  l_iter.filter(fn { x => (x & 1) == 1 }).collect()
}

fn fact(n : Int) -> Int {
  let start = 1
  start.until(n).fold(Int::op_mul, init=start)
}
```

Commonly used methods include:

- `each`: Iterates over each element in the iterator, applying some function to each element.
- `fold`: Folds the elements of the iterator using the given function, starting with the given initial value.
- `collect`: Collects the elements of the iterator into an array.

- `filter`: _lazy_ Filters the elements of the iterator based on a predicate function.
- `map`: _lazy_ Transforms the elements of the iterator using a mapping function.
- `concat`: _lazy_ Combines two iterators into one by appending the elements of the second iterator to the first.

Methods like `filter` `map` are very common on a sequence object e.g. Array.
But what makes `Iter` special is that any method that constructs a new `Iter` is
_lazy_ (i.e. iteration doesn't start on call because it's wrapped inside a
function), as a result of no allocation for intermediate value. That's what
makes `Iter` superior for traversing through sequence: no extra cost. MoonBit
encourages user to pass an `Iter` across functions instead of the sequence
object itself.

Pre-defined sequence structures like `Array` and its iterators should be
enough to use. But to take advantages of these methods when used with a custom
sequence with elements of type `S`, we will need to implement `Iter`, namely, a function that returns
an `Iter[S]`. Take `Bytes` as an example:

```moonbit
fn iter(data : Bytes) -> Iter[Byte] {
  Iter::new(
    fn(yield) {
      // The code that actually does the iteration
      /////////////////////////////////////////////
      for i = 0, len = data.length(); i < len; i = i + 1 {
        if yield(data[i]) == IterEnd {
          break IterEnd
        }
      /////////////////////////////////////////////
      } else {
        IterContinue
      }
    },
  )
}
```

Almost all `Iter` implementations are identical to that of `Bytes`, the only
main difference being the code block that actually does the iteration.

### Implementation details

The type `Iter[T]` is basically a type alias for `((T) -> IterResult) -> IterResult`,
a higher-order function that takes an operation and `IterResult` is an enum
object that tracks the state of current iteration which consists any of the 2
states:

- `IterEnd`: marking the end of an iteration
- `IterContinue`: marking the end of an iteration is yet to be reached, implying the iteration will still continue at this state.

To put it simply, `Iter[T]` takes a function `(T) -> IterResult` and use it to
transform `Iter[T]` itself to a new state of type `IterResult`. Whether that
state being `IterEnd` `IterContinue` depends on the function.

Iterator provides a unified way to iterate through data structures, and they
can be constructed at basically no cost: as long as `fn(yield)` doesn't
execute, the iteration process doesn't start.

Internally a `Iter::run()` is used to trigger the iteration. Chaining all sorts
of `Iter` methods might be visually pleasing, but do notice the heavy work
underneath the abstraction.

Thus, unlike an external iterator, once the iteration starts
there's no way to stop unless the end is reached. Methods such as `count()`
which counts the number of elements in a iterator looks like an `O(1)` operation
but actually has linear time complexity. Carefully use iterators or
performance issue might occur.

## Built-in Data Structures

### Boolean

MoonBit has a built-in boolean type, which has two values: `true` and `false`. The boolean type is used in conditional expressions and control structures.

```moonbit
let a = true
let b = false
let c = a && b
let d = a || b
let e = not(a)
```

### Number

MoonBit have integer type and floating point type:

| type     | description                                                                     | example |
| -------- | ------------------------------------------------------------------------------- | ------- |
| `Int`    | 32-bit signed integer                                                           | `42`    |
| `Int64`  | 64-bit signed integer                                                           | `1000L` |
| `UInt`   | 32-bit unsigned integer                                                         | `14U`   |
| `UInt64` | 64-bit unsigned integer                                                         | `14UL`  |
| `Double` | 64-bit floating point, defined by IEEE754                                       | `3.14`  |
| `Float`  | 32-bit floating point ｜ `(3.14 : Float)`                                       |
| `BigInt` | represents numeric values larger than other types ｜ `10000000000000000000000N` |

MoonBit also supports numeric literals, including decimal, binary, octal, and hexadecimal numbers.

To improve readability, you may place underscores in the middle of numeric literals such as `1_000_000`. Note that underscores can be placed anywhere within a number, not just every three digits.

- There is nothing surprising about decimal numbers.

  ```moonbit
  let a = 1234
  let b = 1_000_000 + a
  let large_num = 9_223_372_036_854_775_807L // Integers of the Int64 type must have an 'L' as a suffix
  let unsigned_num = 4_294_967_295U // Integers of the UInt type must have an 'U' suffix
  ```

- A binary number has a leading zero followed by a letter "B", i.e. `0b`/`0B`.
  Note that the digits after `0b`/`0B` must be `0` or `1`.

  ```moonbit
  let bin =  0b110010
  let another_bin = 0B110010
  ```

- An octal number has a leading zero followed by a letter "O", i.e. `0o`/`0O`.
  Note that the digits after `0o`/`0O` must be in the range from `0` through `7`:

  ```moonbit
  let octal = 0o1234
  let another_octal = 0O1234
  ```

- A hexadecimal number has a leading zero followed by a letter "X", i.e. `0x`/`0X`.
  Note that the digits after the `0x`/`0X` must be in the range `0123456789ABCDEF`.

  ```moonbit
  let hex = 0XA
  let another_hex = 0xA
  ```

#### Overloaded int literal

When the expected type is known, MoonBit can automatically overload integer literal, and there is no need to specify the type of number via letter postfix:

```moonbit
let int : Int = 42
let uint : UInt = 42
let int64 : Int64 = 42
let double : Double = 42
let float : Float = 42
let bigint : BigInt = 42
```

### String

`String` holds a sequence of UTF-16 code units. You can use double quotes to create a string, or use `#|` to write a multi-line string.

```moonbit
let a = "兔rabbit"
println(a[0]) // output: 兔
println(a[1]) // output: r
```

```moonbit
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

```moonbit
let x = 42
println("The answer is \{x}")
```

Variables used for string interpolation must support the `to_string` method.

### Char

`Char` is an integer representing a Unicode code point.

```moonbit
let a : Char = 'A'
let b = '\x41'
let c = '🐰'
let zero = '\u{30}'
let zero = '\u0030'
```

### Byte(s)

A byte literal in MoonBit is either a single ASCII character or a single escape enclosed in single quotes `'`, and preceded by the character `b`. Byte literals are of type `Byte`. For example:

```moonbit live
fn main {
  let b1 : Byte = b'a'
  println(b1.to_int())
  let b2 = b'\xff'
  println(b2.to_int())
}
```

A `Bytes` is a sequence of bytes. Similar to byte, bytes literals have the form of `b"..."`. For example:

```moonbit live
fn main {
  let b1 : Bytes = b"abcd"
  let b2 = b"\x61\x62\x63\x64"
  println(b1 == b2) // true
}
```

### Tuple

A tuple is a collection of finite values constructed using round brackets `()` with the elements separated by commas `,`. The order of elements matters; for example, `(1,true)` and `(true,1)` have different types. Here's an example:

```moonbit
fn pack(a: Bool, b: Int, c: String, d: Double) -> (Bool, Int, String, Double) {
    (a, b, c, d)
}
fn init {
    let quad = pack(false, 100, "text", 3.14)
    let (bool_val, int_val, str, float_val) = quad
    println("\{bool_val} \{int_val} \{str} \{float_val}")
}
```

Tuples can be accessed via pattern matching or index:

```moonbit live
fn f(t : (Int, Int)) -> Unit {
  let (x1, y1) = t // access via pattern matching
  // access via index
  let x2 = t.0
  let y2 = t.1
  if (x1 == x2 && y1 == y2) {
    println("yes")
  } else {
    println("no")
  }
}

fn main {
  f((1, 2))
}
```

### Array

An array is a finite sequence of values constructed using square brackets `[]`, with elements separated by commas `,`. For example:

```moonbit
let numbers = [1, 2, 3, 4]
```

You can use `numbers[x]` to refer to the xth element. The index starts from zero.

```moonbit live
fn main {
  let numbers = [1, 2, 3, 4]
  let a = numbers[2]
  numbers[3] = 5
  let b = a + numbers[3]
  println(b) // prints 8
}
```

### Map

MoonBit provides a hash map data structure that preserves insertion orde called `Map` in its standard library.
`Map`s can be created via a convenient literal syntax:

```moonbit
let map : Map[String, Int] = { "x": 1, "y": 2, "z": 3 }
```

Currently keys in map literal syntax must be constant. `Map`s can also be destructed elegantly with pattern matching, see [Map Pattern](#map-pattern).

## Json literal

MoonBit supports convenient json handling by overloading literals.
When the expected type of an expression is `Json`, number, string, array and map literals can be directly used to create json data:

```moonbit
let moon_pkg_json_example : Json = {
  "import": [ "moonbitlang/core/builtin", "moonbitlang/core/coverage" ],
  "test-import": [ "moonbitlang/core/random" ]
}
```

Json values can be pattern matched too, see [Json Pattern](#json-pattern).

## Variable Binding

A variable can be declared as mutable or immutable using `let mut` or `let`, respectively. A mutable variable can be reassigned to a new value, while an immutable one cannot.

```moonbit live
let zero = 0

fn main {
  let mut i = 10
  i = 20
  println(i + zero)
}
```

## Data Types

There are two ways to create new data types: `struct` and `enum`.

### Struct

In MoonBit, structs are similar to tuples, but their fields are indexed by field names. A struct can be constructed using a struct literal, which is composed of a set of labeled values and delimited with curly brackets. The type of a struct literal can be automatically inferred if its fields exactly match the type definition. A field can be accessed using the dot syntax `s.f`. If a field is marked as mutable using the keyword `mut`, it can be assigned a new value.

```moonbit live
struct User {
  id: Int
  name: String
  mut email: String
}

fn main {
  let u = { id: 0, name: "John Doe", email: "john@doe.com" }
  u.email = "john@doe.name"
  println(u.id)
  println(u.name)
  println(u.email)
}
```

#### Constructing Struct with Shorthand

If you already have some variable like `name` and `email`, it's redundant to repeat those names when constructing a struct:

```moonbit
fn main {
  let name = "john"
  let email = "john@doe.com"
  let u = { id: 0, name: name, email: email }
}
```

You can use shorthand instead, it behaves exactly the same.

```moonbit
fn main {
  let name = "john"
  let email = "john@doe.com"
  let u = { id: 0, name, email }
}
```

#### Struct Update Syntax

It's useful to create a new struct based on an existing one, but with some fields updated.

```moonbit live
struct User {
  id: Int
  name: String
  email: String
} derive(Show)

fn main  {
  let user = { id: 0, name: "John Doe", email: "john@doe.com" }
  let updated_user = { ..user, email: "john@doe.name" }
  println(user)         // output: { id: 0, name: "John Doe", email: "john@doe.com" }
  println(updated_user) // output: { id: 0, name: "John Doe", email: "john@doe.name" }
}
```

### Enum

Enum types are similar to algebraic data types in functional languages. Users familiar with C/C++ may prefer calling it tagged union.

An enum can have a set of cases (constructors). Constructor names must start with capitalized letter. You can use these names to construct corresponding cases of an enum, or checking which branch an enum value belongs to in pattern matching:

```moonbit live
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

fn main {
  print_relation(compare_int(0, 1)) // smaller!
  print_relation(compare_int(1, 1)) // equal!
  print_relation(compare_int(2, 1)) // greater!
}
```

Enum cases can also carry payload data. Here's an example of defining an integer list type using enum:

```moonbit live
enum List {
  Nil
  // constructor `Cons` carries additional payload: the first element of the list,
  // and the remaining parts of the list
  Cons (Int, List)
}

fn main {
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
    Nil => println("nil")
    // Here `x` and `xs` are defining new variables instead of referring to existing variables,
    // if `l` is a `Cons`, then the payload of `Cons` (the first element and the rest of the list)
    // will be bind to `x` and `xs
    Cons(x, xs) => {
      println(x)
      println(",")
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

```moonbit live
enum E {
  // `x` and `y` are labelled argument
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
fn main {
  f(C(x=0, y=0)) // `label=value`
  let x = 0
  f(C(~x, y=1)) // `~x` is an abbreviation for `x=x`
}
```

It is also possible to access labelled arguments of constructors like accessing struct fields in pattern matching:

```moonbit
enum Object {
  Point(~x : Double, ~y : Double)
  Circle(~x : Double, ~y : Double, ~radius : Double)
}

type! NotImplementedError derive(Show)

fn distance_with(self : Object, other : Object) -> Double!NotImplementedError {
  match (self, other) {
    // For variables defined via `Point(..) as p`,
    // the compiler knows it must be of constructor `Point`,
    // so you can access fields of `Point` directly via `p.x`, `p.y` etc.
    (Point(_) as p1, Point(_) as p2) => {
      let dx = p2.x - p1.x
      let dy = p2.y - p1.y
      (dx * dx + dy * dy).sqrt()
    }
    (Point(_), Circle(_)) | (Circle(_), Point(_)) | (Circle(_), Circle(_)) =>
      raise NotImplementedError
  }
}

fn main {
  let p1 : Object = Point(x=0, y=0)
  let p2 : Object = Point(x=3, y=4)
  let c1 : Object = Circle(x=0, y=0, radius=2)
  try {
    println(p1.distance_with!(p2)) // 5.0
    println(p1.distance_with!(c1))
  } catch {
    e => println(e)
  }
}
```

#### Constructor with mutable fields

It is also possible to define mutable fields for constructor. This is especially useful for defining imperative data structures:

```moonbit
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

```moonbit
// `UserId` is a fresh new type different from `Int`, and you can define new methods for `UserId`, etc.
// But at the same time, the internal representation of `UserId` is exactly the same as `Int`
type UserId Int
type UserName String
```

Newtypes are similar to enums with only one constructor (with the same name as the newtype itself). So, you can use the constructor to create values of newtype, or use pattern matching to extract the underlying representation of a newtype:

```moonbit
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

```moonbit
fn init {
  let id: UserId = UserId(1)
  let uid: Int = id.0
  println(uid)
}
```

## Pattern Matching

We have shown a use case of pattern matching for enums, but pattern matching is not restricted to enums. For example, we can also match expressions against Boolean values, numbers, characters, strings, tuples, arrays, and struct literals. Since there is only one case for those types other than enums, we can pattern match them using `let` binding instead of `match` expressions. Note that the scope of bound variables in `match` is limited to the case where the variable is introduced, while `let` binding will introduce every variable to the current scope. Furthermore, we can use underscores `_` as wildcards for the values we don't care about, use `..` to ignore remaining fields of struct or elements of array.

```moonbit
let id = match u {
  { id: id, name: _, email: _ } => id
}
// is equivalent to
let { id: id, name: _, email: _ } = u
// or
let { id: id, ..} = u
```

```moonbit
let ary = [1,2,3,4]
let [a, b, ..] = ary // a = 1, b = 2
let [.., a, b] = ary // a = 3, b = 4
```

There are some other useful constructs in pattern matching. For example, we can use `as` to give a name to some pattern, and we can use `|` to match several cases at once. A variable name can only be bound once in a single pattern, and the same set of variables should be bound on both sides of `|` patterns.

```moonbit
match expr {
  Lit(n) as a => ...
  Add(e1, e2) | Mul(e1, e2) => ...
  _ => ...
}
```

### Map Pattern

MoonBit allows convenient matching on map-like data structures.
Inside a map pattern, the `key : value` syntax will match if `key` exists in the map, and match the value of `key` with pattern `value`.
The `key? : value` syntax will match no matter `key` exists or not, and `value` will be matched against `map[key]` (an optional).

```moonbit
match map {
  // matches if any only if "b" exists in `map`
  { "b": _ } => ..
  // matches if and only if "b" does not exist in `map` and "a" exists in `map`.
  // When matches, bind the value of "a" in `map` to `x`
  { "b"? : None, "a": x } => ..
  // compiler reports missing case: { "b"? : None, "a"? : None }
}
```

- To match a data type `T` using map pattern, `T` must have a method `op_get(Self, K) -> Option[V]` for some type `K` and `V`.
- Currently, the key part of map pattern must be a constant
- Map patterns are always open: unmatched keys are silently ignored
- Map pattern will be compiled to efficient code: every key will be fetched at most once

### Json Pattern

When the matched value has type `Json`, literal patterns can be used directly:

```moonbit
match json {
  { "version": "1.0.0", "import": [..] as imports } => ...
  _ => ...
}
```

## Operators

### Operator Overloading

MoonBit supports operator overloading of builtin operators via methods. The method name corresponding to a operator `<op>` is `op_<op>`. For example:

```moonbit live
struct T {
  x:Int
} derive(Show)

fn op_add(self: T, other: T) -> T {
  { x: self.x + other.x }
}

fn main {
  let a = { x: 0 }
  let b = { x: 2 }
  println(a + b)
}
```

Another example about `op_get` and `op_set`:

```moonbit live
struct Coord {
  mut x: Int
  mut y: Int
} derive(Show)

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

fn main {
  let c = { x: 1, y: 2 }
  println(c)
  println(c["y"])
  c["x"] = 23
  println(c)
  println(c["x"])
}
```

Currently, the following operators can be overloaded:

| Operator Name         | Method Name  |
| --------------------- | ------------ |
| `+`                   | `op_add`     |
| `-`                   | `op_sub`     |
| `*`                   | `op_mul`     |
| `/`                   | `op_div`     |
| `%`                   | `op_mod`     |
| `=`                   | `op_equal`   |
| `<<`                  | `op_shl`     |
| `>>`                  | `op_shr`     |
| `-` (unary)           | `op_neg`     |
| `_[_]` (get item)     | `op_get`     |
| `_[_] = _` (set item) | `op_set`     |
| `_[_:_]` (view)       | `op_as_view` |

### Pipe operator

MoonBit provides a convenient pipe operator `|>`, which can be used to chain regular function calls:

```moonbit
fn init {
  x |> f // equivalent to f(x)
  x |> f(y) // equivalent to f(x, y)

  // Chain calls at multiple lines
  arg_val
  |> f1 // equivalent to f1(arg_val)
  |> f2(other_args) // equivalent to f2(f1(arg_val), other_args)
}
```

### Cascade Operator

The cascade operator `..` is used to perform a series of mutable operations on
the same value consecutively. The syntax is as follows:

```moonbit
x..f()
```

`x..f()..g()` is equivalent to `{x.f(); x.g(); x}`.

Consider the following scenario: for a `MyStringBuilder` type that has methods
like `add_string`, `add_char`, `add_int`, etc., we often need to perform
a series of operations on the same `MyStringBuilder` value:

```moonbit
let builder = MyStringBuilder::new()
builder.add_char('a')
builder.add_char('a')
builder.add_int(1001)
builder.add_string("abcdef")
let result = builder.to_string()
```

To avoid repetitive typing of `builder`, its methods are often designed to
return `self` itself, allowing operations to be chained using the `.` operator.
To distinguish between immutable and mutable operations, in MoonBit,
for all methods that return `Unit`, cascade operator can be used for
consecutive operations without the need to modify the return type of the methods.

```moonbit
let result =
  MyStringBuilder::new()
    ..add_char('a')
    ..add_char('a')
    ..add_int(1001)
    ..add_string("abcdef")
    .to_string()
```

### Bitwise Operator

MoonBit supports C-Style bitwise operators for both 32 bits and 64 bits `Int` and `UInt`, formatter will automatically insert parentheses for bitwise operators to avoid ambiguity.

| Operator | Perform |
| -------- | ------- |
| `&`      | `land`  |
| `\|`     | `lor`   |
| `^`      | `lxor`  |
| `<<`     | `shl`   |
| `>>`     | `shr`   |

## Error Handling

### Error types

The error values used in MoonBit must have an error type. An error type can be
defined in the following forms:

```moonbit
type! E1 Int  // error type E1 has one constructor E1 with an Int payload
type! E2      // error type E2 has one constructor E2 with no payload
type! E3 {    // error type E3 has three constructors like a normal enum type
  A
  B(Int, ~x : String)
  C(mut ~x : String, Char, ~y : Bool)
}
```

The return type of a function can include an error type to indicate that the
function might return an error. For example, the following function `div` might
return an error of type `DivError`:

```moonbit
type! DivError String
fn div(x: Int, y: Int) -> Int!DivError {
  if y == 0 {
    raise DivError("division by zero")
  }
  x / y
}
```

Here, the keyword `raise` is used to interrupt the function execution and return
an error.

### The Default Error Type

MoonBit provides a default error type `Error` that can be used when the concrete
error type is not important. For convenience, you can annotate the function name
or the return type with the suffix `!` to indicate that the `Error` type is
used. For example, the following function signatures are equivalent:

```moonbit
fn f() -> Unit! { .. }
fn f!() -> Unit { .. }
fn f() -> Unit!Error { .. }
```

For anonymous function and matrix function, you can annotate the keyword `fn`
with the `!` suffix to achieve that. For example,

```moonbit
type! IntError Int
fn h(f: (x: Int) -> Int!, x: Int) -> Unit { .. }

fn main {
  let _ = h(fn! { x => raise(IntError(x)) }, 0)     // matrix function
  let _ = h(fn! (x) { x => raise(IntError(x)) }, 0) // anonymous function
}
```

As shown in the above example, the error types defined by `type!` can be used as
value of the type `Error` when the error is raised.

Note that only error types or the type `Error` can be used as errors. For
functions that are generic in the error type, you can use the `Error` bound to
do that. For example,

```moonbit
pub fn unwrap_or_error[T, E : Error](self : Result[T, E]) -> T!E {
  match self {
    Ok(x) => x
    Err(e) => raise e
  }
}
```

Since the type `Error` can include multiple error types, pattern matching on the
`Error` type must use the wildcard `_` to match all error types. For example,

```moonbit
type! E1
type! E2
fn f(e: Error) -> Unit {
  match e {
    E1 => println("E1")
    E2 => println("E2")
    _ => println("unknown error")
  }
}
```

### Handling Errors

There are three ways to handle errors:

- Append `!` after the function name in a function application to rethrow the
  error directly in case of an error, for example:

```moonbit
fn div_reraise(x: Int, y: Int) -> Int!DivError {
  div!(x, y) // Rethrow the error if `div` raised an error
}
```

- Append `?` after the function name to convert the result into a first-class
  value of the `Result` type, for example:

```moonbit
test {
  let res = div?(6, 3)
  inspect!(res, content="Ok(2)")
  let res = div?(6, 0)
  inspect!(res, content="Err(division by zero)")
}
```

- Use `try` and `catch` to catch and handle errors, for example:

```moonbit
fn main {
  try {
    div!(42, 0)
  } catch {
    DivError(s) => println(s)
  } else {
    v => println(v)
  }
}
```

Here, `try` is used to call a function that might throw an error, and `catch` is
used to match and handle the caught error. If no error is caught, the catch
block will not be executed and the `else` block will be executed instead.

The `else` block can be omitted if no action is needed when no error is caught.
For example:

```moonbit
fn main {
  try {
    println(div!(42, 0))
  } catch {
    _ => println("Error")
  }
}
```

The `catch` keyword is optional, and when the body of `try` is a simple
expression, the curly braces can be omitted. For example:

```moonbit
fn main {
  let a = try div!(42, 0) { _ => 0 }
  println(a)
}
```

The `!` and `?` attributes can also be used on method invocation and pipe
operator. For example:

```moonbit live
type T Int
type! E Int derive(Show)
fn f(self: T) -> Unit!E { raise E(self.0) }
fn main {
  let x = T(42)
  try f!(x) { e => println(e) }
  try x.f!() { e => println(e) }
  try x |> f!() { e => println(e) }
}
```

However for infix operators such as `+` `*` that may raise an error,
the original form has to be used, e.g. `x.op_add!(y)`, `x.op_mul!(y)`.

Additionally, if the return type of a function includes an error type, the
function call must use `!` or `?` for error handling, otherwise the compiler
will report an error.

### Error Inference

Within a `try` block, several different kinds of errors can be raised. When that
happens, the compiler will use the type `Error` as the common error type.
Accordingly, the handler must use the wildcard `_` to make sure all errors are
caught. For example,

```moonbit live
type! E1
type! E2
fn f1() -> Unit!E1 { raise E1 }
fn f2() -> Unit!E2 { raise E2 }
fn main {
  try {
    f1!()
    f2!()
  } catch {
    E1 => println("E1")
    E2 => println("E2")
    _ => println("unknown error")
  }
}
```

You can also use `catch!` to rethrow the uncaught errors for convenience. This
is useful when you only want to handle a specific error and rethrow others. For
example,

```moonbit
type! E1
type! E2
fn f1() -> Unit!E1 { raise E1 }
fn f2() -> Unit!E2 { raise E2 }
fn f() -> Unit! {
  try {
    f1!()
    f2!()
  } catch! {
    E1 => println("E1")
  }
}
```

## Generics

Generics are supported in top-level function and data type definitions. Type parameters can be introduced within square brackets. We can rewrite the aforementioned data type `List` to add a type parameter `T` to obtain a generic version of lists. We can then define generic functions over lists like `map` and `reduce`.

```moonbit
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

```moonbit
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

```moonbit
// Package A
pub(readonly) struct RO {
  field: Int
}
fn init {
  let r = { field: 4 }       // OK
  let r = { ..r, field: 8 }  // OK
}

// Package B
fn println(r : RO) -> Unit {
  println("{ field: ")
  println(r.field)  // OK
  println(" }")
}
fn init {
  let r : RO = { field: 4 }  // ERROR: Cannot create values of the public read-only type RO!
  let r = { ..r, field: 8 }  // ERROR: Cannot mutate a public read-only field!
}
```

Access control in MoonBit adheres to the principle that a `pub` type, function, or variable cannot be defined in terms of a private type. This is because the private type may not be accessible everywhere that the `pub` entity is used. MoonBit incorporates sanity checks to prevent the occurrence of use cases that violate this principle.

```moonbit
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

```moonbit
enum MyList[X] {
  Nil
  Cons(X, MyList[X])
}

fn MyList::map[X, Y](xs: MyList[X], f: (X) -> Y) -> MyList[Y] { ... }
fn MyList::concat[X](xs: MyList[MyList[X]]) -> MyList[X] { ... }
```

As a convenient shorthand, when the first parameter of a function is named `self`, MoonBit automatically defines the function as a method of the type of `self`:

```moonbit
fn map[X, Y](self: MyList[X], f: (X) -> Y) -> List[Y] { ... }
// equivalent to
fn MyList::map[X, Y](xs: MyList[X], f: (X) -> Y) -> List[Y] { ... }
```

Methods are just regular functions owned by a type constructor. So when there is no ambiguity, methods can be called using regular function call syntax directly:

```moonbit
fn init {
  let xs: MyList[MyList[_]] = ...
  let ys = concat(xs)
}
```

Unlike regular functions, methods support overloading: different types can define methods of the same name. If there are multiple methods of the same name (but for different types) in scope, one can still call them by explicitly adding a `TypeName::` prefix:

```moonbit
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

```moonbit
// a package named @list
enum List[X] { ... }
fn List::length[X](xs: List[X]) -> Int { ... }

// another package that uses @list
fn init {
  let xs: @list.List[_] = ...
  println(xs.length()) // always work
  println(@list.List::length(xs)) // always work, but verbose
  println(@list.length(xs)) // simpler, but only possible when there is no ambiguity in @list
}
```

## View

Analogous to `slice` in other languages, the view is a reference to a
specific segment of collections. You can use `data[start:end]` to create a
view of array `data`, referencing elements from `start` to `end` (exclusive).
Both `start` and `end` indices can be omitted.

```moonbit
fn init {
  let xs = [0,1,2,3,4,5]
  let s1 : ArrayView[Int] = xs[2:]
  print_array_view(s1)            //output: 2345
  xs[:4]  |> print_array_view()  //output: 0123
  xs[2:5] |> print_array_view()  //output: 234
  xs[:]   |> print_array_view()  //output: 012345

  // create a view of another view
  xs[2:5][1:] |> print_array_view() //output: 34
}

fn print_array_view[T : Show](view : ArrayView[T]) -> Unit {
  for i=0; i<view.length(); i = i + 1 {
    println(view[i])
  }
  println("\n")
}
```

By implementing `length` and `op_as_view` method, you can also create a view for a user-defined type. Here is an example:

```moonbit
struct MyList[A] {
  elems : Array[A]
}

struct MyListView[A] {
  ls : MyList[A]
  start : Int
  end : Int
}

pub fn length[A](self : MyList[A]) -> Int {
  self.elems.length()
}

pub fn op_as_view[A](self : MyList[A], ~start : Int, ~end : Int) -> MyListView[A] {
  println("op_as_view: [\{start},\{end})")
  if start < 0 || end > self.length() { abort("index out of bounds") }
  { ls: self, start, end }
}

fn init {
  let ls = { elems: [1,2,3,4,5] }
  ls[:] |> ignore()
  ls[1:] |> ignore()
  ls[:2] |> ignore()
  ls[1:2] |> ignore()
}
```

Output：

```plaintext
op_as_view: [0,5)
op_as_view: [1,5)
op_as_view: [0,2)
op_as_view: [1,2)
```

## Trait system

MoonBit features a structural trait system for overloading/ad-hoc polymorphism. Traits declare a list of operations, which must be supplied when a type wants to implement the trait. Traits can be declared as follows:

```moonbit
trait I {
  method(...) -> ...
}
```

In the body of a trait definition, a special type `Self` is used to refer to the type that implements the trait.

To implement a trait, a type must provide all the methods required by the trait.
However, there is no need to implement a trait explicitly. Types with the required methods automatically implements a trait. For example, the following trait:

```moonbit
trait Show {
  to_string(Self) -> String
}
```

is automatically implemented by builtin types such as `Int` and `Double`.

When declaring a generic function, the type parameters can be annotated with the traits they should implement, allowing the definition of constrained generic functions. For example:

```moonbit
trait Number {
  op_add(Self, Self) -> Self
  op_mul(Self, Self) -> Self
}

fn square[N: Number](x: N) -> N {
  x * x
}
```

Without the `Number` requirement, the expression `x * x` in `square` will result in a method/operator not found error. Now, the function `square` can be called with any type that implements `Number`, for example:

```moonbit
fn main {
  println(square(2)) // 4
  println(square(1.5)) // 2.25
  println(square({ x: 2, y: 3 })) // {x: 4, y: 9}
}

trait Number {
  op_add(Self, Self) -> Self
  op_mul(Self, Self) -> Self
}

fn square[N: Number](x: N) -> N {
  x * x
}

struct Point {
  x: Int
  y: Int
} derive(Show)

fn op_add(self: Point, other: Point) -> Point {
  { x: self.x + other.x, y: self.y + other.y }
}

fn op_mul(self: Point, other: Point) -> Point {
  { x: self.x * other.x, y: self.y * other.y }
}
```

Methods of a trait can be called directly via `Trait::method`. MoonBit will infer the type of `Self` and check if `Self` indeed implements `Trait`, for example:

```moonbit live
fn main {
  println(Show::to_string(42))
  println(Compare::compare(1.0, 2.5))
}
```

MoonBit provides the following useful builtin traits:

```moonbit
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
  // writes a string representation of `Self` into a `Logger`
  output(Self, Logger) -> Unit
  to_string(Self) -> String
}

trait Default {
  default() -> Self
}
```

## Access control of methods and direct implementation of traits

To make the trait system coherent (i.e. there is a globally unique implementation for every `Type: Trait` pair), and prevent third-party packages from modifying behavior of existing programs by accident, _only the package that defines a type can define methods for it_. So one cannot define new methods or override old methods for builtin and foreign types.

However, it is often useful to implement new traits for an existing type. So MoonBit provides a mechanism to directly implement a trait, defined using the syntax `impl Trait for Type with method_name(...) { ... }`. Type annotations can be omitted from `impl`, because MoonBit can infer the correct types from the trait's signature. For example, to implement a new trait `ToMyBinaryProtocol` for builtin types, one can (and must) use `impl`:

```moonbit
trait ToMyBinaryProtocol {
  to_my_binary_protocol(Self, Buffer) -> Unit
}

impl ToMyBinaryProtocol for Int with to_my_binary_protocol(x, b) { ... }
impl ToMyBinaryProtocol for Int with to_my_binary_protocol(x, b) { ... }
impl ToMyBinaryProtocol for Int with to_my_binary_protocol(x, b) { ... }
impl[X : ToMyBinaryProtocol] for Array[X] with to_my_binary_protocol(arr, b) { ... }
```

When searching for the implementation of a trait, `impl`s have a higher priority, so they can be used to override ordinary methods with undesirable behavior. `impl`s can only be used to implement the specified trait. They cannot be called directly like ordinary methods. Furthermore, _only the package of the type or the package of the trait can define an implementation_. For example, only `@pkg1` and `@pkg2` are allowed to define `impl @pkg1.Trait for @pkg2.Type` for type `@pkg2.Type`. This restriction ensures that MoonBit's trait system is still coherent with the extra flexibility of `impl`s.

To invoke an trait implementation directly, one can use the `Trait::method` syntax:

```moonbit live
trait MyTrait {
  f(Self) -> Unit
}

impl MyTrait for Int with f(self) { println("Got Int \{self}!") }

fn main {
  MyTrait::f(42)
}
```

## Automatically derive builtin traits

MoonBit can automatically derive implementations for some builtin traits:

```moonbit live
struct T {
  x: Int
  y: Int
} derive(Eq, Compare, Show, Default)

fn main {
  let t1 = T::default()
  let t2 = { x: 1, y: 1 }
  println(t1) // {x: 0, y: 0}
  println(t2) // {x: 1, y: 1}
  println(t1 == t2) // false
  println(t1 < t2) // true
}
```

## Trait objects

MoonBit supports runtime polymorphism via trait objects.
If `t` is of type `T`, which implements trait `I`,
one can pack the methods of `T` that implements `I`, together with `t`,
into a runtime object via `t as I`.
Trait object erases the concrete type of a value,
so objects created from different concrete types can be put in the same data structure and handled uniformly:

```moonbit live
trait Animal {
  speak(Self) -> Unit
}

type Duck String
fn Duck::make(name: String) -> Duck { Duck(name) }
fn speak(self: Duck) -> Unit {
  println(self.0 + ": quack!")
}

type Fox String
fn Fox::make(name: String) -> Fox { Fox(name) }
fn Fox::speak(_self: Fox) -> Unit {
  println("What does the fox say?")
}

fn main {
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

Users can define new methods for trait objects, just like defining new methods for structs and enums:

```moonbit
trait Logger {
  write_string(Self, String) -> Unit
}

trait CanLog {
  log(Self, Logger) -> Unit
}

fn Logger::write_object[Obj : CanLog](self : Logger, obj : Obj) -> Unit {
  obj.log(self)
}

// use the new method to simplify code
impl[A : CanLog, B : CanLog] CanLog for (A, B) with log(self, logger) {
  let (a, b) = self
  logger
  ..write_string("(")
  ..write_object(a)
  ..write_string(", ")
  ..write_object(b)
  .write_string(")")
}
```

## Test Blocks

MoonBit provides the test code block for writing test cases. For example:

```moonbit
test "test_name" {
  assert_eq!(1 + 1, 2)
  assert_eq!(2 + 2, 4)
}
```

A test code block is essentially a function that returns a `Unit` but may throws a `String` on error, or `Unit!String` as one would see in its signature at the position of return type. It is called during the execution of `moon test` and outputs a test report through the build system. The `assert_eq` function is from the standard library; if the assertion fails, it prints an error message and terminates the test. The string `"test_name"` is used to identify the test case and is optional. If it starts with `"panic"`, it indicates that the expected behavior of the test is to trigger a panic, and the test will only pass if the panic is triggered. For example:

```moonbit
test "panic_test" {
  let _ : Int = Option::None.unwrap()
}
```

## Doc Comments

Doc comments are comments prefix with `///` in each line in the leading of toplevel structure like `fn`,`let`,`enum`,`struct`,`type`. The doc comments contains a markdown text and several pragmas.

````moonbit
/// Return a new array with reversed elements.
///
/// # Example
///
/// ```
/// reverse([1,2,3,4]) |> println()
/// ```
fn reverse[T](xs : Array[T]) -> Array[T] {
  ...
}
````

### Pragmas

Pragmas are annotations inside doc comments. They all take the form `/// @word ...`. The _word_ indicates the type of pragma and is followed optionally by several _word_ or string literals. Pragmas do not normally affect the meaning of programs. Unrecognized pragmas will be reported as warnings.

- Alert Pragmas

  Alert pragmas in doc comments of functions will be reported when those functions are referenced. This mechanism is a generalized way to mark functions as `deprecated` or `unsafe`.

  It takes the form `@alert category "alert message..."`.

  The category can be an arbitrary identifier. It allows configuration to decide which alerts are enabled or turned into errors.

  ```moonbit
  /// @alert deprecated "Use foo2 instead"
  pub fn foo() -> Unit { ... }

  /// @alert unsafe "Div will cause an error when y is zero"
  pub fn div(x: Int, y: Int) -> Int { ... }

  fn main {
    foo() // warning: Use foo2 instead
    div(x, y) |> ignore // warning: Div will cause an error when y is zero
  }
  ```

## MoonBit's build system

The introduction to the build system is available at [MoonBit's Build System Tutorial](https://moonbitlang.github.io/moon/).
