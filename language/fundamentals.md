# Fundamentals

## Built-in Data Structures

### Unit

`Unit` is a built-in type in MoonBit that represents the absence of a meaningful value. It has only one value, written as `()`. `Unit` is similar to `void` in languages like C/C++/Java, but unlike `void`, it is a real type and can be used anywhere a type is expected.

The `Unit` type is commonly used as the return type for functions that perform some action but do not produce a meaningful result:

```moonbit
fn print_hello() -> Unit {
  println("Hello, world!")
}
```

Unlike some other languages, MoonBit treats `Unit` as a first-class type, allowing it to be used in generics, stored in data structures, and passed as function arguments.

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

| type     | description                                       | example                    |
|----------|---------------------------------------------------|----------------------------|
| `Int16`  | 16-bit signed integer                             | `(42 : Int16)`             |
| `Int`    | 32-bit signed integer                             | `42`                       |
| `Int64`  | 64-bit signed integer                             | `1000L`                    |
| `UInt16` | 16-bit unsigned integer                           | `(14 : UInt16)`            |
| `UInt`   | 32-bit unsigned integer                           | `14U`                      |
| `UInt64` | 64-bit unsigned integer                           | `14UL`                     |
| `Double` | 64-bit floating point, defined by IEEE754         | `3.14`                     |
| `Float`  | 32-bit floating point                             | `(3.14 : Float)`           |
| `BigInt` | represents numeric values larger than other types | `10000000000000000000000N` |

MoonBit also supports numeric literals, including decimal, binary, octal, and hexadecimal numbers.

To improve readability, you may place underscores in the middle of numeric literals such as `1_000_000`. Note that underscores can be placed anywhere within a number, not just every three digits.

- Decimal numbers can have underscore between the numbers.

  By default, an int literal is signed 32-bit number. For unsigned numbers, a postfix `U` is needed; for 64-bit numbers, a postfix `L` is needed.
  ```moonbit
  let a = 1234
  let b : Int = 1_000_000 + a
  let unsigned_num       : UInt   = 4_294_967_295U
  let large_num          : Int64  = 9_223_372_036_854_775_807L
  let unsigned_large_num : UInt64 = 18_446_744_073_709_551_615UL
  ```
- A binary number has a leading zero followed by a letter "B", i.e. `0b`/`0B`.
  Note that the digits after `0b`/`0B` must be `0` or `1`.
  ```moonbit
  let bin = 0b110010
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
  let another_hex = 0xA_B_C
  ```
- A floating-point number literal is 64-bit floating-point number. To define a float, type annotation is needed.
  ```moonbit
  let double = 3.14 // Double
  let float : Float = 3.14
  let float2 = (3.14 : Float)
  ```

  A 64-bit floating-point number can also be defined using hexadecimal format:
  ```moonbit
  let hex_double = 0x1.2P3 // (1.0 + 2 / 16) * 2^(+3) == 9
  ```

When the expected type is known, MoonBit can automatically overload literal, and there is no need to specify the type of number via letter postfix:

```moonbit
let int : Int = 42
let uint : UInt = 42
let int64 : Int64 = 42
let double : Double = 42
let float : Float = 42
let bigint : BigInt = 42
```

#### SEE ALSO
[Overloaded Literals]()

### String

`String` holds a sequence of UTF-16 code units. You can use double quotes to create a string, or use `#|` to write a multi-line string.

```moonbit
let a = "兔rabbit"
println(a.code_unit_at(0).to_char())
println(a.code_unit_at(1).to_char())
let b =
  #| Hello
  #| MoonBit\n
  #|
println(b)
```

```default
Some('兔')
Some('r')
 Hello
 MoonBit\n

```

In double quotes string, a backslash followed by certain special characters forms an escape sequence:

| escape sequences       | description                                          |
|------------------------|------------------------------------------------------|
| `\n`, `\r`, `\t`, `\b` | New line, Carriage return, Horizontal tab, Backspace |
| `\\`                   | Backslash                                            |
| `\u5154` , `\u{1F600}` | Unicode escape sequence                              |

MoonBit supports string interpolation. It enables you to substitute variables within interpolated strings. This feature simplifies the process of constructing dynamic strings by directly embedding variable values into the text. Variables used for string interpolation must implement the [`Show` trait](methods.md#builtin-traits).

```moonbit
let x = 42
println("The answer is \{x}")
```

#### NOTE
The interpolated expression can not contain newline, `{}` or `"`.

Multi-line strings can be defined using the leading `#|` or `$|`, where the former will keep the raw string and the latter will perform the escape and interpolation:

```moonbit
let lang = "MoonBit"
let raw =
  #| Hello
  #| ---
  #| \{lang}
  #| ---
let interp =
  $| Hello
  $| ---
  $| \{lang}
  $| ---
println(raw)
println(interp)
```

```default
 Hello
 ---
 \{lang}
 ---
 Hello
 ---
 MoonBit
 ---
```

Avoid mixing `$|` and `#|` within the same multi-line string; pick one style for the whole block.

The [VSCode extension](../toolchain/vscode/index.md#actions) includes an action that can turn pasted documents into a plain multi-line string and switch between plain text and MoonBit multi-line strings.

When the expected type is `String` , the array literal syntax is overloaded to
construct the `String` by specifying each character in the string.

```moonbit
test {
  let c : Char = '中'
  let s : String = [c, '文']
  inspect(s, content="中文")
}
```

#### SEE ALSO
API: [https://mooncakes.io/docs/moonbitlang/core/string](https://mooncakes.io/docs/moonbitlang/core/string)

[Overloaded Literals]()

### Char

`Char` represents a Unicode code point.

```moonbit
let a : Char = 'A'
let b = '兔'
let zero = '\u{30}'
let zero = '\u0030'
```

Char literals can be overloaded to type `Int` or `UInt16` when it is the expected type:

```moonbit
test {
  let s : String = "hello"
  let b : UInt16 = s.code_unit_at(0) // 'h'
  assert_eq(b, 'h') // 'h' is overloaded to UInt16
  let c : Int = '兔'
  // Not ok : exceed range
  // let d : UInt16 = '𠮷'
}
```

#### SEE ALSO
API: [https://mooncakes.io/docs/moonbitlang/core/char](https://mooncakes.io/docs/moonbitlang/core/char)

[Overloaded Literals]()

### Byte(s)

A byte literal in MoonBit is either a single ASCII character or a single escape, have the form of `b'...'`. Byte literals are of type `Byte`. For example:

```moonbit
fn main {
  let b1 : Byte = b'a'
  println(b1.to_int())
  let b2 = b'\xff'
  println(b2.to_int())
}
```

```default
97
255
```

A `Bytes` is an immutable sequence of bytes. Similar to byte, bytes literals have the form of `b"..."`. For example:

```moonbit
test {
  let b1 : Bytes = b"abcd"
  let b2 = b"\x61\x62\x63\x64"
  assert_eq(b1, b2)
}
```

The byte literal and bytes literal also support escape sequences, but different from those in string literals. The following table lists the supported escape sequences for byte and bytes literals:

| escape sequences       | description                                          |
|------------------------|------------------------------------------------------|
| `\n`, `\r`, `\t`, `\b` | New line, Carriage return, Horizontal tab, Backspace |
| `\\`                   | Backslash                                            |
| `\x41`                 | Hexadecimal escape sequence                          |
| `\o102`                | Octal escape sequence                                |

#### NOTE
You can use `@buffer.T` to construct bytes by writing various types of data. For example:

```moonbit
test "buffer 1" {
  let buf : @buffer.Buffer = @buffer.new()
  buf.write_bytes(b"Hello")
  buf.write_byte(b'!')
  assert_eq(buf.contents(), b"Hello!")
}
```

When the expected type is `Bytes`, the `b` prefix can be omitted. Array literals can also be overloaded to construct a `Bytes` sequence by specifying each byte in the sequence.

```moonbit
test {
  let b : Byte = '\xFF'
  let bs : Bytes = [b, '\x01']
  inspect(
    bs,
    content=(
      #|b"\xff\x01"
    ),
  )
}
```

#### SEE ALSO
API for `Byte`: [https://mooncakes.io/docs/moonbitlang/core/byte](https://mooncakes.io/docs/moonbitlang/core/byte)<br />
\\\\
API for `Bytes`: [https://mooncakes.io/docs/moonbitlang/core/bytes](https://mooncakes.io/docs/moonbitlang/core/bytes)<br />
\\\\
API for `@buffer.T`: [https://mooncakes.io/docs/moonbitlang/core/buffer](https://mooncakes.io/docs/moonbitlang/core/buffer)

[Overloaded Literals]()

### Tuple

A tuple is a collection of finite values constructed using round brackets `()` with the elements separated by commas `,`. The order of elements matters; for example, `(1,true)` and `(true,1)` have different types. Here's an example:

```moonbit
fn main {
  fn pack(
    a : Bool,
    b : Int,
    c : String,
    d : Double
  ) -> (Bool, Int, String, Double) {
    (a, b, c, d)
  }

  let quad = pack(false, 100, "text", 3.14)
  let (bool_val, int_val, str, float_val) = quad
  println("\{bool_val} \{int_val} \{str} \{float_val}")
}
```

```default
false 100 text 3.14
```

Tuples can be accessed via pattern matching or index:

```moonbit
test {
  let t = (1, 2)
  let (x1, y1) = t
  let x2 = t.0
  let y2 = t.1
  assert_eq(x1, x2)
  assert_eq(y1, y2)
}
```

### Ref

A `Ref[T]` is a mutable reference containing a value `val` of type `T`.

It can be constructed using `{ val : x }`, and can be accessed using `ref.val`. See [struct]() for detailed explanation.

```moonbit
let a : Ref[Int] = { val: 100 }

test {
  a.val = 200
  assert_eq(a.val, 200)
  a.val += 1
  assert_eq(a.val, 201)
}
```

#### SEE ALSO
API: [https://mooncakes.io/docs/moonbitlang/core/ref](https://mooncakes.io/docs/moonbitlang/core/ref)

### Option and Result

`Option` and `Result` are the most common types to represent a possible error or failure in MoonBit.

- `Option[T]` represents a possibly missing value of type `T`. It can be abbreviated as `T?`.
- `Result[T, E]` represents either a value of type `T` or an error of type `E`.

See [enum]() for detailed explanation.

```moonbit
test {
  let a : Int? = None
  let b : Option[Int] = Some(42)
  let c : Result[Int, String] = Ok(42)
  let d : Result[Int, String] = Err("error")
  match a {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
  match d {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}
```

#### SEE ALSO
API for `Option`: [https://mooncakes.io/docs/moonbitlang/core/option](https://mooncakes.io/docs/moonbitlang/core/option)<br />
\\\\
API for `Result`: [https://mooncakes.io/docs/moonbitlang/core/result](https://mooncakes.io/docs/moonbitlang/core/result)

### Array

An array is a finite sequence of values constructed using square brackets `[]`, with elements separated by commas `,`. For example:

```moonbit
let numbers = [1, 2, 3, 4]
```

You can use `numbers[x]` to refer to the xth element. The index starts from zero.

```moonbit
test {
  let numbers = [1, 2, 3, 4]
  let a = numbers[2]
  numbers[3] = 5
  let b = a + numbers[3]
  assert_eq(b, 8)
}
```

There are `Array[T]` and `FixedArray[T]`:

`Array[T]` can grow in size, while `FixedArray[T]` has a fixed size, thus it needs to be created with initial value.

#### WARNING
A common pitfall is creating `FixedArray` with the same initial value:

```moonbit
test {
  let two_dimension_array = FixedArray::make(10, FixedArray::make(10, 0))
  two_dimension_array[0][5] = 10
  assert_eq(two_dimension_array[5][5], 10)
}
```

This is because all the cells reference to the same object (the `FixedArray[Int]` in this case). One should use `FixedArray::makei()` instead which creates an object for each index.

```moonbit
test {
  let two_dimension_array = FixedArray::makei(10, fn(_i) {
    FixedArray::make(10, 0)
  })
  two_dimension_array[0][5] = 10
  assert_eq(two_dimension_array[5][5], 0)
}
```

When the expected type is known, MoonBit can automatically overload array, otherwise
`Array[T]` is created:

```moonbit
let fixed_array_1 : FixedArray[Int] = [1, 2, 3]

let fixed_array_2 = ([1, 2, 3] : FixedArray[Int])

let array_3 : Array[Int] = [1, 2, 3] // Array[Int]
```

#### SEE ALSO
API: [https://mooncakes.io/docs/moonbitlang/core/array](https://mooncakes.io/docs/moonbitlang/core/array)

[Overloaded Literals]()

#### ArrayView

Analogous to `slice` in other languages, the view is a reference to a
specific segment of collections. You can use `data[start:end]` to create a
view of array `data`, referencing elements from `start` to `end` (exclusive).
Both `start` and `end` indices can be omitted.

#### NOTE
`ArrayView` is an immutable data structure on its own, but the underlying `Array` or `FixedArray`
could be modified.

```moonbit
test {
  let xs = [0, 1, 2, 3, 4, 5]
  let s1 : ArrayView[Int] = xs[2:]
  inspect(s1, content="[2, 3, 4, 5]")
  inspect(xs[:4], content="[0, 1, 2, 3]")
  inspect(xs[2:5], content="[2, 3, 4]")
  inspect(xs[:], content="[0, 1, 2, 3, 4, 5]")
}
```

#### SEE ALSO
API: [https://mooncakes.io/docs/moonbitlang/core/array](https://mooncakes.io/docs/moonbitlang/core/array)

### Map

MoonBit provides a hash map data structure that preserves insertion order called `Map` in its standard library.
`Map`s can be created via a convenient literal syntax:

```moonbit
let map : Map[String, Int] = { "x": 1, "y": 2, "z": 3 }
```

Currently keys in map literal syntax must be constant. `Map`s can also be destructed elegantly with pattern matching, see [Map Pattern]().

#### SEE ALSO
API: [https://mooncakes.io/docs/moonbitlang/core/builtin#Map](https://mooncakes.io/docs/moonbitlang/core/builtin#Map)

[Overloaded Literals]()

### Json

MoonBit supports convenient json handling by overloading literals.
When the expected type of an expression is `Json`, number, string, array and map literals can be directly used to create json data:

```moonbit
let moon_pkg_json_example : Json = {
  "import": ["moonbitlang/core/builtin", "moonbitlang/core/coverage"],
  "test-import": ["moonbitlang/core/random"],
}
```

Json values can be pattern matched too, see [Json Pattern]().

#### SEE ALSO
API: [https://mooncakes.io/docs/moonbitlang/core/json](https://mooncakes.io/docs/moonbitlang/core/json)

[Overloaded Literals]()

## Overloaded Literals

Overloaded literals allow you to use the same syntax to represent different types of values.
For example, you can use `1` to represent `UInt` or `Double` depending on the expected type. If the expected type is not known, the literal will be interpreted as `Int` by default.

```moonbit
fn expect_double(x : Double) -> Unit {

}

test {
  let x = 1 // type of x is Int
  let y : Double = 1
  expect_double(1)
}
```

The overloaded literals can be composed. If array literal can be overloaded to `Bytes` , and number literal can be overloaded to `Byte` , then you can overload `[1,2,3]` to `Bytes` as well. Here is a table of overloaded literals in MoonBit:

| Overloaded literal                                          | Default type   | Can be overloaded to                                                              |
|-------------------------------------------------------------|----------------|-----------------------------------------------------------------------------------|
| `10`, `0xFF`, `0o377`, `10_000`                             | `Int`          | `UInt`, `Int64`, `UInt64`, `Int16`, `UInt16`, `Byte`, `Double`, `Float`, `BigInt` |
| `"str"`                                                     | `String`       | `Bytes`                                                                           |
| `'c'`                                                       | `Char`         | `Int` , `Byte`                                                                    |
| `3.14`                                                      | `Double`       | `Float`                                                                           |
| `[a, b, c]` (where the types of literals a, b, and c are E) | `Array[E]`     | `FixedArray[E]`, `String`  (if E is of type Char), `Bytes` (if E is of type Byte) |

There are also some similar overloading rules in pattern. For more details, see [Pattern Matching]().

#### NOTE
Literal overloading is not the same as value conversion. To convert a variable to a different type, you can use methods prefixed with `to_`, such as `to_int()`, `to_double()`, etc.

### Escape Sequences in Overloaded Literals

Escape sequences can be used in overloaded `"..."` literals and `'...'` literals. The interpretation of escape sequences depends on the types they are overloaded to:

- Simple escape sequences

  Including `\n`, `\r`, `\t`, `\\`, and `\b`. These escape sequences are supported in any `"..."` or `'...'` literals. They are interpreted as their respective `Char` or `Byte` in `String` or `Bytes`.
- Byte escape sequences

  The `\x41` and `\o102` escape sequences represent a Byte. These are supported in literals overloaded to `Bytes` and `Byte`.
- Unicode escape sequences

  The `\u5154` and `\u{1F600}` escape sequences represent a `Char`. These are supported in literals of type `String` and `Char`.

## Functions

Functions take arguments and produce a result. In MoonBit, functions are first-class, which means that functions can be arguments or return values of other functions. MoonBit's naming convention requires that function names should not begin with uppercase letters (A-Z). Compare for constructors in the `enum` section below.

### Top-Level Functions

Functions can be defined as top-level or local. We can use the `fn` keyword to define a top-level function that sums three integers and returns the result, as follows:

```moonbit
fn add3(x : Int, y : Int, z : Int) -> Int {
  x + y + z
}
```

Note that the arguments and return value of top-level functions require **explicit** type annotations.

### Local Functions

Local functions can be named or anonymous. Type annotations can be omitted for local function definitions: they can be automatically inferred in most cases. For example:

```moonbit
fn local_1() -> Int {
  fn inc(x) { // named as `inc`
    x + 1
  }
  // anonymous, instantly applied to integer literal 6
  (fn(x) { x + inc(2) })(6)
}

test {
  assert_eq(local_1(), 9)
}
```

For simple anonymous function, MoonBit provides a very concise syntax called arrow function:

```moonbit
  [1, 2, 3].eachi((i, x) => println("\{i} => \{x}"))
  // parenthesis can be omitted when there is only one parameter
  [1, 2, 3].each(x => println(x * x))
```

Functions, whether named or anonymous, are *lexical closures*: any identifiers without a local binding must refer to bindings from a surrounding lexical scope. For example:

```moonbit
let global_y = 3

fn local_2(x : Int) -> (Int, Int) {
  fn inc() {
    x + 1
  }

  fn four() {
    global_y + 1
  }

  (inc(), four())
}

test {
  assert_eq(local_2(3), (4, 4))
}
```

A local function can only refer to itself and other previously defined local functions.
To define  mutually recursive local functions, use the syntax `letrec f = .. and g = ..` instead:

```moonbit
  fn f(x) {
    // `f` can refer to itself here, but cannot use `g`
    if x > 0 {
      f(x - 1)
    }
  }

  fn g(x) {
    // `g` can refer to `f` and `g` itself
    if x < 0 {
      f(-x)
    } else {
      f(x)
    }
  }
  // mutually recursive local functions
  letrec even = x => x == 0 || odd(x - 1)
  and odd = x => x != 0 && even(x - 1)
```

### Function Applications

A function can be applied to a list of arguments in parentheses:

```moonbit
add3(1, 2, 7)
```

This works whether `add3` is a function defined with a name (as in the previous example), or a variable bound to a function value, as shown below:

```moonbit
test {
  let add3 = fn(x, y, z) { x + y + z }
  assert_eq(add3(1, 2, 7), 10)
}
```

The expression `add3(1, 2, 7)` returns `10`. Any expression that evaluates to a function value is applicable:

```moonbit
test {
  let f = fn(x) { x + 1 }
  let g = fn(x) { x + 2 }
  let w = (if true { f } else { g })(3)
  assert_eq(w, 4)
}
```

### Partial Applications

Partial application is a technique of applying a function to some of its arguments, resulting in a new function that takes the remaining arguments. In MoonBit, partial application is achieved by using the `_` operator in function application:

```moonbit
fn add(x : Int, y : Int) -> Int {
  x + y
}

test {
  let add10 : (Int) -> Int = add(10, _)
  println(add10(5)) // prints 15
  println(add10(10)) // prints 20
}
```

The `_` operator represents the missing argument in parentheses. The partial application allows multiple `_` in the same parentheses.
For example, `Array::fold(_, _, init=5)` is equivalent to `fn(x, y) { Array::fold(x, y, init=5) }`.

The `_` operator can also be used in enum creation, dot style function calls and in the pipelines.

### Labelled arguments

**Top-level** functions can declare labelled argument with the syntax `label~ : Type`. `label` will also serve as parameter name inside function body:

```moonbit
fn labelled_1(arg1~ : Int, arg2~ : Int) -> Int {
  arg1 + arg2
}
```

Labelled arguments can be supplied via the syntax `label=arg`. `label=label` can be abbreviated as `label~`:

```moonbit
test {
  let arg1 = 1
  assert_eq(labelled_1(arg2=2, arg1~), 3)
}
```

Labelled function can be supplied in any order. The evaluation order of arguments is the same as the order of parameters in function declaration.

### Optional arguments

An argument can be made optional by supplying a default expression with the syntax `label?: Type = default_expr`, where the `default_expr` may be omitted. If this argument is not supplied at call site, the default expression will be used:

```moonbit
fn optional(opt? : Int = 42) -> Int {
  opt
}

test {
  assert_eq(optional(), 42)
  assert_eq(optional(opt=0), 0)
}
```

The default expression will be evaluated every time it is used. And the side effect in the default expression, if any, will also be triggered. For example:

```moonbit
fn incr(counter? : Ref[Int] = { val: 0 }) -> Ref[Int] {
  counter.val = counter.val + 1
  counter
}

test {
  inspect(incr(), content="{val: 1}")
  inspect(incr(), content="{val: 1}")
  let counter : Ref[Int] = { val: 0 }
  inspect(incr(counter~), content="{val: 1}")
  inspect(incr(counter~), content="{val: 2}")
}
```

If you want to share the result of default expression between different function calls, you can lift the default expression to a toplevel `let` declaration:

```moonbit
let default_counter : Ref[Int] = { val: 0 }

fn incr_2(counter? : Ref[Int] = default_counter) -> Int {
  counter.val = counter.val + 1
  counter.val
}

test {
  assert_eq(incr_2(), 1)
  assert_eq(incr_2(), 2)
}
```

The default expression can depend on previous arguments, such as:

```moonbit
fn create_rectangle(a : Int, b? : Int = a) -> (Int, Int) {
  (a, b)
}

test {
  inspect(create_rectangle(10), content="(10, 10)")
}
```

#### Optional arguments without default values

It is quite common to have different semantics when a user does not provide a value.
Optional arguments without default values have type `T?` and `None` as the default value.
When supplying this kind of optional argument directly, MoonBit will automatically wrap the value with `Some`:

```moonbit
fn new_image(width? : Int, height? : Int) -> Image {
  if width is Some(w) {
    ...
  }
  ...
}

let img2 : Image = new_image(width=1920, height=1080)
```

Sometimes, it is also useful to pass a value of type `T?` directly,
for example when forwarding optional argument.
MoonBit provides a syntax `label?=value` for this, with `label?` being an abbreviation of `label?=label`:

```moonbit
fn image(width? : Int, height? : Int) -> Image {
  ...
}

fn fixed_width_image(height? : Int) -> Image {
  image(width=1920, height?)
}
```

### Autofill arguments

MoonBit supports filling specific types of arguments automatically at different call site, such as the source location of a function call.
To declare an autofill argument, simply declare a labelled argument, and add a function attribute `#callsite(autofill(param_a, param_b))`.
Now if the argument is not explicitly supplied, MoonBit will automatically fill it at the call site.

Currently MoonBit supports two types of autofill arguments, `SourceLoc`, which is the source location of the whole function call,
and `ArgsLoc`, which is an array containing the source location of each argument, if any:

```moonbit
#callsite(autofill(loc, args_loc))
fn f(_x : Int, loc~ : SourceLoc, args_loc~ : ArgsLoc) -> String {
  (
    $|loc of whole function call: \{loc}
    $|loc of arguments: \{args_loc}
  )
  // loc of whole function call: <filename>:7:3-7:10
  // loc of arguments: [Some(<filename>:7:5-7:6), Some(<filename>:7:8-7:9), None, None]
}
```

Autofill arguments are very useful for writing debugging and testing utilities.

### Function alias

MoonBit allows calling functions with alternative names via function alias. Function alias can be declared as follows:

```moonbit
#alias(g)
#alias(h, visibility="pub")
fn k() -> Bool {
  true
}
```

You can also create function alias that has different visibility with the field `visibility`.

## Control Structures

### Conditional Expressions

A conditional expression consists of a condition, a consequent, and an optional `else` clause or `else if` clause.

```moonbit
if x == y {
  expr1
} else if x == z {
  expr2
} else {
  expr3
}
```

The curly brackets around the consequent are required.

Note that a conditional expression always returns a value in MoonBit, and the return values of the consequent and the else clause must be of the same type. Here is an example:

```moonbit
let initial = if size < 1 { 1 } else { size }
```

The `else` clause can only be omitted if the return value has type `Unit`.

### Match Expression

The `match` expression is similar to conditional expression, but it uses [pattern matching]() to decide which consequent to evaluate and extracting variables at the same time.

```moonbit
fn decide_sport(weather : String, humidity : Int) -> String {
  match weather {
    "sunny" => "tennis"
    "rainy" => if humidity > 80 { "swimming" } else { "football" }
    _ => "unknown"
  }
}

test {
  assert_eq(decide_sport("sunny", 0), "tennis")
}
```

If a possible condition is omitted, the compiler will issue a warning, and the program will terminate if that case were reached.

### Guard Statement

The `guard` statement is used to check a specified invariant.
If the condition of the invariant is satisfied, the program continues executing
the subsequent statements and returns. If the condition is not satisfied (i.e., false),
the code in the `else` block is executed and its evaluation result is returned (the subsequent statements are skipped).

```moonbit
fn guarded_get(array : Array[Int], index : Int) -> Int? {
  guard index >= 0 && index < array.length() else { None }
  Some(array[index])
}

test {
  inspect(guarded_get([1, 2, 3], -1), content="None")
}
```

#### Guard statement and is expression

The `let` statement can be used with [pattern matching](). However, `let` statement can only handle one case. And using [is expression]() with `guard` statement can solve this issue.

In the following example, `getProcessedText` assumes that the input `path` points to resources that are all plain text,
and it uses the `guard` statement to ensure this invariant while extracting the plain text resource.
Compared to using a `match` statement, the subsequent processing of `text` can have one less level of indentation.

```moonbit
enum Resource {
  Folder(Array[String])
  PlainText(String)
  JsonConfig(Json)
}

fn getProcessedText(
  resources : Map[String, Resource],
  path : String,
) -> String raise Error {
  guard resources.get(path) is Some(resource) else { fail("\{path} not found") }
  guard resource is PlainText(text) else { fail("\{path} is not plain text") }
  process(text)
}
```

When the `else` part is omitted, the program terminates if the condition specified
in the `guard` statement is not true or cannot be matched.

```moonbit
guard condition  // <=> guard condition else { panic() }
guard expr is Some(x)
// <=> guard expr is Some(x) else { _ => panic() }
```

### While loop

In MoonBit, `while` loop can be used to execute a block of code repeatedly as long as a condition is true. The condition is evaluated before executing the block of code. The `while` loop is defined using the `while` keyword, followed by a condition and the loop body. The loop body is a sequence of statements. The loop body is executed as long as the condition is true.

```moonbit
fn main {
  let mut i = 5
  while i > 0 {
    println(i)
    i = i - 1
  }
}
```

```default
5
4
3
2
1
```

The loop body supports `break` and `continue`. Using `break` allows you to exit the current loop, while using `continue` skips the remaining part of the current iteration and proceeds to the next iteration.

```moonbit
fn main {
  let mut i = 5
  while i > 0 {
    i = i - 1
    if i == 4 {
      continue
    }
    if i == 1 {
      break
    }
    println(i)
  }
}
```

```default
3
2
```

The `while` loop also supports an optional `else` clause. When the loop condition becomes false, the `else` clause will be executed, and then the loop will end.

```moonbit
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

```default
2
1
0
```

When there is an `else` clause, the `while` loop can also return a value. The return value is the evaluation result of the `else` clause. In this case, if you use `break` to exit the loop, you need to provide a return value after `break`, which should be of the same type as the return value of the `else` clause.

```moonbit
fn main {
  let mut i = 10
  let r = while i > 0 {
    i = i - 1
    if i % 2 == 0 {
      break 5
    }
  } else {
    7
  }
  println(r)
}
```

```default
5
```

```moonbit
fn main {
  let mut i = 10
  let r = while i > 0 {
    i = i - 1
  } else {
    7
  }
  println(r)
}
```

```default
7
```

### For Loop

MoonBit also supports C-style For loops. The keyword `for` is followed by variable initialization clauses, loop conditions, and update clauses separated by semicolons. They do not need to be enclosed in parentheses.
For example, the code below creates a new variable binding `i`, which has a scope throughout the entire loop and is immutable. This makes it easier to write clear code and reason about it:

```moonbit
fn main {
  for i = 0; i < 5; i = i + 1 {
    println(i)
  }
}
```

```default
0
1
2
3
4
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
for i = 1; ; i = i + 1 {
  println(i)
}
for {
  println("loop forever")
}
```

The `for` loop also supports `continue`, `break`, and `else` clauses. Like the `while` loop, the `for` loop can also return a value using the `break` and `else` clauses.

The `continue` statement skips the remaining part of the current iteration of the `for` loop (including the update clause) and proceeds to the next iteration. The `continue` statement can also update the binding variables of the `for` loop, as long as it is followed by expressions that match the number of binding variables, separated by commas.

For example, the following program calculates the sum of even numbers from 1 to 6:

```moonbit
fn main {
  let sum = for i = 1, acc = 0; i <= 6; i = i + 1 {
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

```default
even: 2
even: 4
even: 6
12
```

### `for .. in` loop

MoonBit supports traversing elements of different data structures and sequences via the `for .. in` loop syntax:

```moonbit
for x in [1, 2, 3] {
  println(x)
}
```

`for .. in` loop is translated to the use of `Iter` in MoonBit's standard library. Any type with a method `.iter() : Iter[T]` can be traversed using `for .. in`.
For more information of the `Iter` type, see [Iterator]() below.

`for .. in` loop also supports iterating through a sequence of integers, such as:

```moonbit
test {
  let mut i = 0
  for j in 0..<10 {
    i += j
  }
  assert_eq(i, 45)
  let mut k = 0
  for l in 0..=10 {
    k += l
  }
  assert_eq(k, 55)
}
```

In addition to sequences of a single value, MoonBit also supports traversing sequences of two values, such as `Map`, via the `Iter2` type in MoonBit's standard library.
Any type with method `.iter2() : Iter2[A, B]` can be traversed using `for .. in` with two loop variables:

```moonbit
for k, v in { "x": 1, "y": 2, "z": 3 } {
  println(k)
  println(v)
}
```

Another example of `for .. in` with two loop variables is traversing an array while keeping track of array index:

```moonbit
fn main {
  for index, elem in [4, 5, 6] {
    let i = index + 1
    println("The \{i}-th element of the array is \{elem}")
  }
}
```

```default
The 1-th element of the array is 4
The 2-th element of the array is 5
The 3-th element of the array is 6
```

Control flow operations such as `return`, `break` and error handling are supported in the body of `for .. in` loop:

```moonbit
fn main {
  let map = { "x": 1, "y": 2, "z": 3, "w": 4 }
  for k, v in map {
    if k == "y" {
      continue
    }
    println("\{k}, \{v}")
    if k == "z" {
      break
    }
  }
}
```

```default
x, 1
z, 3
```

If a loop variable is unused, it can be ignored with `_`.

### Functional loop

Functional loop is a powerful feature in MoonBit that enables you to write loops in a functional style.

A functional loop consumes an argument and returns a value. It is defined using the `loop` keyword, followed by its argument and the loop body. The loop body is a sequence of clauses, each of which consists of a pattern and an expression. The clause whose pattern matches the input will be executed, and the loop will return the value of the expression. If no pattern matches, the loop will panic. Use the `continue` keyword with arguments to start the next iteration of the loop. Use the `break` keyword with an argument to return a value from the loop. The `break` keyword can be omitted if the value is the last expression in the loop body.

```moonbit
test {
  fn sum(xs : @list.List[Int]) -> Int {
    loop (xs, 0) {
      (Empty, acc) => break acc // <=> Nil, acc => acc
      (More(x, tail=rest), acc) => continue (rest, x + acc)
    }
  }

  assert_eq(sum(@list.from_array([1, 2, 3])), 6)
}
```

### Labelled Continue/Break

When a loop is labelled, it can be referenced from a `break` or `continue` from
within a nested loop. For example:

```moonbit
test "break label" {
  let mut count = 0
  let xs = [1, 2, 3]
  let ys = [4, 5, 6]
  let res = outer~: for i in xs {
    for j in ys {
      count = count + i
      break outer~ j
    }
  } else {
    -1
  }
  assert_eq(res, 4)
  assert_eq(count, 1)
}

test "continue label" {
  let mut count = 0
  let init = 10
  let res = outer~: loop init {
    0 => 42
    i =>
      for {
        count = count + 1
        continue outer~ i - 1
      }
  }
  assert_eq(res, 42)
  assert_eq(count, 10)
}
```

### `defer` expression

`defer` expression can be used to perform reliable resource cleanup.
The syntax for `defer` is as follows:

```moonbit
defer <expr>
<body>
```

Whenever the program leaves `body`, `expr` will be executed.
For example, the following program:

```moonbit
  defer println("perform resource cleanup")
  println("do things with the resource")
```

will first print `do things with the resource`, and then `perform resource cleanup`.
`defer` expression will always get executed no matter how its body exits.
It can handle [error](error-handling.md),
as well as control flow constructs including `return`, `break` and `continue`.

Consecutive `defer` will be executed in reverse order, for example, the following:

```moonbit
  defer println("first defer")
  defer println("second defer")
  println("do things")
```

will output first `do things`, then `second defer`, and finally `first defer`.

`return`, `break` and `continue` are disallowed in the right hand side of `defer`.
Currently, raising error or calling `async` function is also disallowed in the right hand side of `defer`.

## Iterator

An iterator is an object that traverse through a sequence while providing access
to its elements. Traditional OO languages like Java's `Iterator<T>` use `next()`
`hasNext()` to step through the iteration process, whereas functional languages
(JavaScript's `forEach`, Lisp's `mapcar`) provides a high-order function which
takes an operation and a sequence then consumes the sequence with that operation
being applied to the sequence. The former is called *external iterator* (visible
to user) and the latter is called *internal iterator* (invisible to user).

The built-in type `Iter[T]` is MoonBit's external iterator implementation. It
exposes `next()` to pull the next value: it returns `Some(value)` and advances
the iterator, or `None` when the iteration is finished.
Almost all built-in sequential data structures have implemented `Iter`:

```moonbit
///|
fn filter_even(l : Array[Int]) -> Array[Int] {
  let l_iter : Iter[Int] = l.iter()
  l_iter.filter(x => (x & 1) == 0).collect()
}

///|
fn fact(n : Int) -> Int {
  let start = 1
  let range : Iter[Int] = start.until(n)
  range.fold(Int::mul, init=start)
}
```

Commonly used methods include:

- `each`: Iterates over each element in the iterator, applying some function to each element.
- `fold`: Folds the elements of the iterator using the given function, starting with the given initial value.
- `collect`: Collects the elements of the iterator into an array.
- `filter`: *lazy* Filters the elements of the iterator based on a predicate function.
- `map`: *lazy* Transforms the elements of the iterator using a mapping function.
- `concat`: *lazy* Combines two iterators into one by appending the elements of the second iterator to the first.

Methods like `filter` and `map` are very common on a sequence object e.g. Array.
But what makes `Iter` special is that any method that constructs a new `Iter` is
*lazy* (i.e. iteration doesn't start on call because it's wrapped inside a
function), as a result of no allocation for intermediate value. That's what
makes `Iter` superior for traversing through sequence: no extra cost. MoonBit
encourages user to pass an `Iter` across functions instead of the sequence
object itself.

Pre-defined sequence structures like `Array` and its iterators should be
enough to use. But to take advantages of these methods when used with a custom
sequence with elements of type `S`, we will need to implement `Iter`, namely, a function that returns
an `Iter[S]`. Take `Bytes` as an example:

```moonbit
///|
fn iter(data : Bytes) -> Iter[Byte] {
  let mut index = 0
  Iter::new(fn() -> Byte? {
    if index < data.length() {
      let byte = data[index]
      index += 1
      Some(byte)
    } else {
      None
    }
  })
}
```

Iterators are single-pass: once you call `next()` or consume them with methods
like `each`, `fold`, or `collect`, their internal state advances and cannot be
reset. If you need to traverse the sequence again, request a new `Iter` from
the source.

## Custom Data Types

There are two ways to create new data types: `struct` and `enum`.

### Struct

In MoonBit, structs are similar to tuples, but their fields are indexed by field names. A struct can be constructed using a struct literal, which is composed of a set of labeled values and delimited with curly brackets. The type of a struct literal can be automatically inferred if its fields exactly match the type definition. A field can be accessed using the dot syntax `s.f`. If a field is marked as mutable using the keyword `mut`, it can be assigned a new value.

```moonbit
struct User {
  id : Int
  name : String
  mut email : String
}
```

```moonbit
fn main {
  let u = User::{ id: 0, name: "John Doe", email: "john@doe.com" }
  u.email = "john@doe.name"
  //! u.id = 10
  println(u.id)
  println(u.name)
  println(u.email)
}
```

```default
0
John Doe
john@doe.name
```

#### Constructing Struct with Shorthand

If you already have some variable like `name` and `email`, it's redundant to repeat those names when constructing a struct. You can use shorthand instead, it behaves exactly the same:

```moonbit
let name = "john"
let email = "john@doe.com"
let u = User::{ id: 0, name, email }
```

If there's no other struct that has the same fields, it's redundant to add the struct's name when constructing it:

```moonbit
let u2 = { id: 0, name, email }
```

#### Struct Update Syntax

It's useful to create a new struct based on an existing one, but with some fields updated.

```moonbit
fn main {
  let user = { id: 0, name: "John Doe", email: "john@doe.com" }
  let updated_user = { ..user, email: "john@doe.name" }
  println(
    (
      $|{ id: \{user.id}, name: \{user.name}, email: \{user.email} }
      $|{ id: \{updated_user.id}, name: \{updated_user.name}, email: \{updated_user.email} }
    ),
  )
}
```

```default
{ id: 0, name: John Doe, email: john@doe.com }
{ id: 0, name: John Doe, email: john@doe.name }
```

### Enum

Enum types are similar to algebraic data types in functional languages. Users familiar with C/C++ may prefer calling it tagged union.

An enum can have a set of cases (constructors). Constructor names must start with capitalized letter. You can use these names to construct corresponding cases of an enum, or checking which branch an enum value belongs to in pattern matching:

```moonbit
/// An enum type that represents the ordering relation between two values,
/// with three cases "Smaller", "Greater" and "Equal"
enum Relation {
  Smaller
  Greater
  Equal
}
```

```moonbit
/// compare the ordering relation between two integers
fn compare_int(x : Int, y : Int) -> Relation {
  if x < y {
    // when creating an enum, if the target type is known, 
    // you can write the constructor name directly
    Smaller
  } else if x > y {
    // but when the target type is not known,
    // you can always use `TypeName::Constructor` to create an enum unambiguously
    Relation::Greater
  } else {
    Equal
  }
}

/// output a value of type `Relation`
fn print_relation(r : Relation) -> Unit {
  // use pattern matching to decide which case `r` belongs to
  match r {
    // during pattern matching, if the type is known, 
    // writing the name of constructor is sufficient
    Smaller => println("smaller!")
    // but you can use the `TypeName::Constructor` syntax 
    // for pattern matching as well
    Relation::Greater => println("greater!")
    Equal => println("equal!")
  }
}
```

```moonbit
fn main {
  print_relation(compare_int(0, 1))
  print_relation(compare_int(1, 1))
  print_relation(compare_int(2, 1))
}
```

```default
smaller!
equal!
greater!
```

Enum cases can also carry payload data. Here's an example of defining an integer list type using enum:

```moonbit
enum Lst {
  Nil
  // constructor `Cons` carries additional payload: the first element of the list,
  // and the remaining parts of the list
  Cons(Int, Lst)
}
```

```moonbit
// In addition to binding payload to variables,
// you can also continue matching payload data inside constructors.
// Here's a function that decides if a list contains only one element
fn is_singleton(l : Lst) -> Bool {
  match l {
    // This branch only matches values of shape `Cons(_, Nil)`, 
    // i.e. lists of length 1
    Cons(_, Nil) => true
    // Use `_` to match everything else
    _ => false
  }
}

fn print_list(l : Lst) -> Unit {
  // when pattern-matching an enum with payload,
  // in additional to deciding which case a value belongs to
  // you can extract the payload data inside that case
  match l {
    Nil => println("nil")
    // Here `x` and `xs` are defining new variables 
    // instead of referring to existing variables,
    // if `l` is a `Cons`, then the payload of `Cons` 
    // (the first element and the rest of the list)
    // will be bind to `x` and `xs
    Cons(x, xs) => {
      println("\{x},")
      print_list(xs)
    }
  }
}
```

```moonbit
fn main {
  // when creating values using `Cons`, the payload of by `Cons` must be provided
  let l : Lst = Cons(1, Cons(2, Nil))
  println(is_singleton(l))
  print_list(l)
}
```

```default
false
1,
2,
nil
```

#### Constructor with labelled arguments

Enum constructors can have labelled argument:

```moonbit
enum E {
  // `x` and `y` are labelled argument
  C(x~ : Int, y~ : Int)
}
```

```moonbit
// pattern matching constructor with labelled arguments
fn f(e : E) -> Unit {
  match e {
    // `label=pattern`
    C(x=0, y=0) => println("0!")
    // `x~` is an abbreviation for `x=x`
    // Unmatched labelled arguments can be omitted via `..`
    C(x~, ..) => println(x)
  }
}
```

```moonbit
fn main {
  f(C(x=0, y=0))
  let x = 0
  f(C(x~, y=1)) // <=> C(x=x, y=1)
}
```

```default
0!
0
```

It is also possible to access labelled arguments of constructors like accessing struct fields in pattern matching:

```moonbit
enum Object {
  Point(x~ : Double, y~ : Double)
  Circle(x~ : Double, y~ : Double, radius~ : Double)
}

suberror NotImplementedError derive(Show)

fn Object::distance_with(
  self : Object,
  other : Object,
) -> Double raise NotImplementedError {
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
```

```moonbit
fn main {
  let p1 : Object = Point(x=0, y=0)
  let p2 : Object = Point(x=3, y=4)
  let c1 : Object = Circle(x=0, y=0, radius=2)
  try {
    println(p1.distance_with(p2))
    println(p1.distance_with(c1))
  } catch {
    e => println(e)
  }
}
```

```default
5
NotImplementedError
```

#### Constructor with mutable fields

It is also possible to define mutable fields for constructor. This is especially useful for defining imperative data structures:

```moonbit
// A set implemented using mutable binary search tree.
struct Set[X] {
  mut root : Tree[X]
}

fn[X : Compare] Set::insert(self : Set[X], x : X) -> Unit {
  self.root = self.root.insert(x, parent=Nil)
}

// A mutable binary search tree with parent pointer
enum Tree[X] {
  Nil
  // only labelled arguments can be mutable
  Node(
    mut value~ : X,
    mut left~ : Tree[X],
    mut right~ : Tree[X],
    mut parent~ : Tree[X]
  )
}

// In-place insert a new element to a binary search tree.
// Return the new tree root
fn[X : Compare] Tree::insert(
  self : Tree[X],
  x : X,
  parent~ : Tree[X],
) -> Tree[X] {
  match self {
    Nil => Node(value=x, left=Nil, right=Nil, parent~)
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

### Tuple Struct

MoonBit supports a special kind of struct called tuple struct:

```moonbit
struct UserId(Int)

struct UserInfo(UserId, String)
```

Tuple structs are similar to enum with only one constructor (with the same name as the tuple struct itself). So, you can use the constructor to create values, or use pattern matching to extract the underlying representation:

```moonbit
fn main {
  let id : UserId = UserId(1)
  let name : UserInfo = UserInfo(id, "John Doe")
  let UserId(uid) = id // uid : Int
  let UserInfo(_, uname) = name // uname: String
  println(uid)
  println(uname)
}
```

```default
1
John Doe
```

Besides pattern matching, you can also use index to access the elements similar to tuple:

```moonbit
fn main {
  let id : UserId = UserId(1)
  let info : UserInfo = UserInfo(id, "John Doe")
  let uid : Int = id.0
  let uname : String = info.1
  println(uid)
  println(uname)
}
```

```default
1
John Doe
```

### Type alias

MoonBit supports type alias via the syntax `type NewType = OldType`:

#### WARNING
The old syntax `typealias OldType as NewType` may be removed in the future.

```moonbit
pub type Index = Int
pub type MyIndex = Int
pub type MyMap = Map[Int, String]
```

Unlike all other kinds of type declaration above, type alias does not define a new type,
it is merely a type macro that behaves exactly the same as its definition.
So for example one cannot define new methods or implement traits for a type alias.

### Local types

MoonBit supports declaring structs/enums at the top of a toplevel
function, which are only visible within the current toplevel function. These
local types can use the generic parameters of the toplevel function but cannot
introduce additional generic parameters themselves. Local types can derive
methods using derive, but no additional methods can be defined manually. For
example:

```moonbit
fn[T : Show] toplevel(x : T) -> Unit {
  enum LocalEnum {
    A(T)
    B(Int)
  } derive(Show)
  struct LocalStruct {
    a : (String, T)
  } derive(Show)
  struct LocalStructTuple(T) derive(Show)
  ...
}
```

Currently, local types do not support being declared as error types.

## Pattern Matching

Pattern matching allows us to match on specific pattern and bind data from data structures.

### Simple Patterns

We can pattern match expressions against

- literals, such as boolean values, numbers, chars, strings, etc
- constants
- structs
- enums
- arrays
- maps
- JSONs

and so on. We can define identifiers to bind the matched values so that they can be used later.

```moonbit
const ONE = 1

fn match_int(x : Int) -> Unit {
  match x {
    0 => println("zero")
    ONE => println("one")
    value => println(value)
  }
}
```

We can use `_` as wildcards for the values we don't care about, and use `..` to ignore remaining fields of struct or enum, or array (see [array pattern]()).

```moonbit
struct Point3D {
  x : Int
  y : Int
  z : Int
}

fn match_point3D(p : Point3D) -> Unit {
  match p {
    { x: 0, .. } => println("on yz-plane")
    _ => println("not on yz-plane")
  }
}

enum Point[T] {
  Point2D(Int, Int, name~ : String, payload~ : T)
}

fn[T] match_point(p : Point[T]) -> Unit {
  match p {
    //! Point2D(0, 0) => println("2D origin")
    Point2D(0, 0, ..) => println("2D origin")
    Point2D(_) => println("2D point")
    _ => panic()
  }
}
```

We can use `as` to give a name to some pattern, and we can use `|` to match several cases at once. A variable name can only be bound once in a single pattern, and the same set of variables should be bound on both sides of `|` patterns.

```moonbit
match expr {
  //! Add(e1, e2) | Lit(e1) => ...
  Lit(n) as a => ...
  Add(e1, e2) | Mul(e1, e2) => ...
  ...
}
```

### Array Pattern

Array patterns can be used to match on the following types to obtain their
corresponding elements or views:

| Type                                  | Element   | View         |
|---------------------------------------|-----------|--------------|
| Array[T], ArrayView[T], FixedArray[T] | T         | ArrayView[T] |
| Bytes, BytesView                      | Byte      | BytesView    |
| String, StringView                    | Char      | StringView   |

Array patterns have the following forms:

- `[]` : matching for empty array
- `[pa, pb, pc]` : matching for array of length three, and bind `pa`, `pb`, `pc`
  to the three elements
- `[pa, ..rest, pb]` : matching for array with at least two elements, and bind
  `pa` to the first element, `pb` to the last element, and `rest` to the
  remaining elements. the binder `rest` can be omitted if the rest of the
  elements are not needed. Arbitrary number of elements are allowed preceding
  and following the `..` part. Because `..` can match uncertain number of
  elements, it can appear at most once in an array pattern.

```moonbit
test {
  let ary = [1, 2, 3, 4]
  if ary is [a, b, .. rest] && a == 1 && b == 2 && rest.length() == 2 {
    inspect("a = \{a}, b = \{b}", content="a = 1, b = 2")
  } else {
    fail("")
  }
  guard ary is [.., a, b] else { fail("") }
  inspect("a = \{a}, b = \{b}", content="a = 3, b = 4")
}
```

Array patterns provide a unicode-safe way to manipulate strings, meaning that it
respects the code unit boundaries. For example, we can check if a string is a
palindrome:

```moonbit
test {
  fn palindrome(s : String) -> Bool {
    loop s.view() {
      [] | [_] => true
      [a, .. rest, b] => if a == b { continue rest } else { false }
    }
  }

  inspect(palindrome("abba"), content="true")
  inspect(palindrome("中b中"), content="true")
  inspect(palindrome("文bb中"), content="false")
}
```

When there are consecutive char or byte constants in an array pattern, the
pattern spread `..` operator can be used to combine them to make the code look
cleaner. Note that in this case the `..` followed by string or bytes constant
matches exact number of elements so its usage is not limited to once.

```moonbit
const NO : Bytes = "no"

test {
  fn match_string(s : String) -> Bool {
    match s {
      [.. "yes", ..] => true // equivalent to ['y', 'e', 's', ..]
    }
  }

  fn match_bytes(b : Bytes) -> Bool {
    match b {
      [.. NO, ..] => false // equivalent to ['n', 'o', ..]
    }
  }
}
```

### Range Pattern

For builtin integer types and `Char`, MoonBit allows matching whether the value falls in a specific range.

Range patterns have the form `a..<b` or `a..=b`, where `..<` means the upper bound is exclusive, and `..=` means inclusive upper bound.
`a` and `b` can be one of:

- literal
- named constant declared with `const`
- `_`, meaning the pattern has no restriction on this side

Here are some examples:

```moonbit
const Zero = 0

fn sign(x : Int) -> Int {
  match x {
    _..<Zero => -1
    Zero => 0
    1..<_ => 1
  }
}

fn classify_char(c : Char) -> String {
  match c {
    'a'..='z' => "lowercase"
    'A'..='Z' => "uppercase"
    '0'..='9' => "digit"
    _ => "other"
  }
}
```

### Map Pattern

MoonBit allows convenient matching on map-like data structures.
Inside a map pattern, the `key : value` syntax will match if `key` exists in the map, and match the value of `key` with pattern `value`.
The `key? : value` syntax will match no matter `key` exists or not, and `value` will be matched against `map[key]` (an optional).

```moonbit
match map {
  // matches if any only if "b" exists in `map`
  { "b": _, .. } => ...
  // matches if and only if "b" does not exist in `map` and "a" exists in `map`.
  // When matches, bind the value of "a" in `map` to `x`
  { "b"? : None, "a": x, .. } => ...
  // compiler reports missing case: { "b"? : None, "a"? : None }
}
```

- To match a data type `T` using map pattern, `T` must have a method `op_get(Self, K) -> Option[V]` for some type `K` and `V` (see [method and trait](methods.md)).
- Currently, the key part of map pattern must be a literal or constant
- Map patterns are always open: the unmatched keys are silently ignored, and `..` needs to be added to identify this nature
- Map pattern will be compiled to efficient code: every key will be fetched at most once

### Json Pattern

When the matched value has type `Json`, literal patterns can be used directly, together with constructors:

```moonbit
match json {
  { "version": "1.0.0", "import": [..] as imports, .. } => ...
  { "version": Number(i, ..), "import": Array(imports), .. } => ...
  ...
}
```

### Guard condition

Each case in a pattern matching expression can have a guard condition. A guard
condition is a boolean expression that must be true for the case to be matched.
If the guard condition is false, the case is skipped and the next case is tried.
For example:

```moonbit
fn guard_cond(x : Int?) -> Int {
  fn f(x : Int) -> Array[Int] {
    [x, x + 42]
  }

  match x {
    Some(a) if f(a) is [0, b] => a + b
    Some(b) => b
    None => -1
  }
}

test {
  assert_eq(guard_cond(None), -1)
  assert_eq(guard_cond(Some(0)), 42)
  assert_eq(guard_cond(Some(1)), 1)
}
```

Note that the guard conditions will not be considered when checking if all
patterns are covered by the match expression. So you will see a warning of
partial match for the following case:

```moonbit
fn guard_check(x : Int?) -> Unit {
  match x {
    Some(a) if a >= 0 => ()
    Some(a) if a < 0 => ()
    None => ()
  }
}
```

#### WARNING
It is not encouraged to call a function that mutates a part of the value being
matched inside a guard condition. When such case happens, the part being mutated
will not be re-evaluated in the subsequent patterns. Use it with caution.

## Generics

Generics are supported in top-level function and data type definitions. Type parameters can be introduced within square brackets. We can rewrite the aforementioned data type `List` to add a type parameter `T` to obtain a generic version of lists. We can then define generic functions over lists like `map` and `reduce`.

```moonbit
///|
enum List[T] {
  Nil
  Cons(T, List[T])
}

///|
fn[S, T] List::map(self : List[S], f : (S) -> T) -> List[T] {
  match self {
    Nil => Nil
    Cons(x, xs) => Cons(f(x), xs.map(f))
  }
}

///|
fn[S, T] List::reduce(self : List[S], op : (T, S) -> T, init : T) -> T {
  match self {
    Nil => init
    Cons(x, xs) => xs.reduce(op, op(init, x))
  }
}
```

## Special Syntax

### Pipelines

MoonBit provides a convenient pipe syntax `x |> f(y)`, which can be used to chain regular function calls:

```moonbit
5 |> ignore // <=> ignore(5)
[] |> Array::push(5) // <=> Array::push([], 5)
1
|> add(5) // <=> add(1, 5)
|> x => { x + 1 }
|> ignore // <=> ignore(add(1, 5))
```

The MoonBit code follows the *data-first* style, meaning the function places its "subject" as the first argument.
Thus, the pipe operator inserts the left-hand side value into the first argument of the right-hand side function call by default.
For example, `x |> f(y)` is equivalent to `f(x, y)`.

You can use the `_` operator to insert `x` into any argument of the function `f`, such as `x |> f(y, _)`, which is equivalent to `f(y, x)`. Labeled arguments are also supported.

The pipe operator can also connect to an arrow function. When piping into an arrow function, the function body must be wrapped in curly braces, for example `value |> x => { x + 1 }`.

### Cascade Operator

The cascade operator `..` is used to perform a series of mutable operations on
the same value consecutively. The syntax is as follows:

```moonbit
[]..append([1])
```

- `x..f()..g()` is equivalent to `{ x.f(); x.g(); }`.
- `x..f().g()` is equivalent to `{ x.f(); x.g(); }`.

Consider the following scenario: for a `StringBuilder` type that has methods
like `write_string`, `write_char`, `write_object`, etc., we often need to perform
a series of operations on the same `StringBuilder` value:

```moonbit
let builder = StringBuilder::new()
builder.write_char('a')
builder.write_char('a')
builder.write_object(1001)
builder.write_string("abcdef")
let result = builder.to_string()
```

To avoid repetitive typing of `builder`, its methods are often designed to
return `self` itself, allowing operations to be chained using the `.` operator.
To distinguish between immutable and mutable operations, in MoonBit,
for all methods that return `Unit`, cascade operator can be used for
consecutive operations without the need to modify the return type of the methods.

```moonbit
let result = StringBuilder::new()
  ..write_char('a')
  ..write_char('a')
  ..write_object(1001)
  ..write_string("abcdef")
  .to_string()
```

### is Expression

The `is` expression tests whether a value conforms to a specific pattern. It
returns a `Bool` value and can be used anywhere a boolean value is expected,
for example:

```moonbit
fn[T] is_none(x : T?) -> Bool {
  x is None
}

fn start_with_lower_letter(s : String) -> Bool {
  s is ['a'..='z', ..]
}
```

Pattern binders introduced by `is` expressions can be used in the following
contexts:

1. In boolean AND expressions (`&&`):
   binders introduced in the left-hand expression can be used in the right-hand
   expression
   ```moonbit
   fn f(x : Int?) -> Bool {
     x is Some(v) && v >= 0
   }
   ```
2. In the first branch of `if` expression: if the condition is a sequence of
   boolean expressions `e1 && e2 && ...`, the binders introduced by the `is`
   expression can be used in the branch where the condition evaluates to `true`.
   ```moonbit
   fn g(x : Array[Int?]) -> Unit {
     if x is [v, .. rest] && v is Some(i) && i is (0..=10) {
       println(v)
       println(i)
       println(rest)
     }
   }
   ```
3. In the following statements of a `guard` condition:
   ```moonbit
   fn h(x : Int?) -> Unit {
     guard x is Some(v)
     println(v)
   }
   ```
4. In the body of a `while` loop:
   ```moonbit
   fn i(x : Int?) -> Unit {
     let mut m = x
     while m is Some(v) {
       println(v)
       m = None
     }
   }
   ```

Note that `is` expression can only take a simple pattern. If you need to use
`as` to bind the pattern to a variable, you have to add parentheses. For
example:

```moonbit
fn j(x : Int) -> Int? {
  Some(x)
}

fn init {
  guard j(42) is (Some(a) as b)
  println(a)
  println(b)
}
```

### Spread Operator

MoonBit provides a spread operator to expand a sequence of elements when
constructing `Array`, `String`, and `Bytes` using the array literal syntax. To
expand such a sequence, it needs to be prefixed with `..`, and it must have
`iter()` method that yields the corresponding type of element.

For example, we can use the spread operator to construct an array:

```moonbit
test {
  let a1 : Array[Int] = [1, 2, 3]
  let a2 : FixedArray[Int] = [4, 5, 6]
  let a3 : @list.List[Int] = @list.from_array([7, 8, 9])
  let a : Array[Int] = [..a1, ..a2, ..a3, 10]
  inspect(a, content="[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]")
}
```

Similarly, we can use the spread operator to construct a string:

```moonbit
test {
  let s1 : String = "Hello"
  let s2 : StringView = "World".view()
  let s3 : Array[Char] = [..s1, ' ', ..s2, '!']
  let s : String = [..s1, ' ', ..s2, '!', ..s3]
  inspect(s, content="Hello World!Hello World!")
}
```

The last example shows how the spread operator can be used to construct a bytes
sequence.

```moonbit
test {
  let b1 : Bytes = "hello"
  let b2 : BytesView = b1[1:4]
  let b : Bytes = [..b1, ..b2, 10]
  inspect(
    b,
    content=(
      #|b"helloell\x0a"
    ),
  )
}
```

### TODO syntax

The `todo` syntax (`...`) is a special construct used to mark sections of code that are not yet implemented or are placeholders for future functionality. For example:

```moonbit
fn todo_in_func() -> Int {
  ...
}
```
