# Built-in Data Structures

## Unit

`Unit` is a built-in type in MoonBit that represents the absence of a meaningful value. It has only one value, written as `()`. `Unit` is similar to `void` in languages like C/C++/Java, but unlike `void`, it is a real type and can be used anywhere a type is expected.

The `Unit` type is commonly used as the return type for functions that perform some action but do not produce a meaningful result:

```{code-block} moonbit
:class: top-level
fn print_hello() -> Unit {
  println("Hello, world!")
}
```

Unlike some other languages, MoonBit treats `Unit` as a first-class type, allowing it to be used in generics, stored in data structures, and passed as function arguments.

## Boolean

MoonBit has a built-in boolean type, which has two values: `true` and `false`. The boolean type is used in conditional expressions and control structures.

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:dedent:
:start-after: start boolean 1
:end-before: end boolean 1
```

## Number

MoonBit have integer type and floating point type:

| type     | description                                       | example                    |
| -------- | ------------------------------------------------- | -------------------------- |
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

  ```{literalinclude} /sources/language/src/builtin/top.mbt
  :language: moonbit
  :dedent:
  :start-after: start number 1
  :end-before: end number 1
  ```

- A binary number has a leading zero followed by a letter "B", i.e. `0b`/`0B`.
  Note that the digits after `0b`/`0B` must be `0` or `1`.

  ```{literalinclude} /sources/language/src/builtin/top.mbt
  :language: moonbit
  :dedent:
  :start-after: start number 2
  :end-before: end number 2
  ```

- An octal number has a leading zero followed by a letter "O", i.e. `0o`/`0O`.
  Note that the digits after `0o`/`0O` must be in the range from `0` through `7`:

  ```{literalinclude} /sources/language/src/builtin/top.mbt
  :language: moonbit
  :dedent:
  :start-after: start number 3
  :end-before: end number 3
  ```

- A hexadecimal number has a leading zero followed by a letter "X", i.e. `0x`/`0X`.
  Note that the digits after the `0x`/`0X` must be in the range `0123456789ABCDEF`.

  ```{literalinclude} /sources/language/src/builtin/top.mbt
  :language: moonbit
  :dedent:
  :start-after: start number 4
  :end-before: end number 4
  ```

- A floating-point number literal is 64-bit floating-point number. To define a float, type annotation is needed.

  ```{literalinclude} /sources/language/src/builtin/top.mbt
  :language: moonbit
  :dedent:
  :start-after: start number 6
  :end-before: end number 6
  ```

  A 64-bit floating-point number can also be defined using hexadecimal format:

  ```{literalinclude} /sources/language/src/builtin/top.mbt
  :language: moonbit
  :dedent:
  :start-after: start number 7
  :end-before: end number 7
  ```

When the expected type is known, MoonBit can automatically overload literal, and there is no need to specify the type of number via letter postfix:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:dedent:
:start-after: start number 5
:end-before: end number 5

```

```{seealso}
[Overloaded Literals](overloaded-literals.md)
```

## String

`String` holds a sequence of UTF-16 code units. You can use double quotes to create a string, or use `#|` to write a multi-line string.

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:dedent:
:start-after: start string 1
:end-before: end string 1
```

```{literalinclude} /sources/language/src/builtin/__snapshot__/string_1
:caption: Output
```

In double quotes string, a backslash followed by certain special characters forms an escape sequence:

| escape sequences     | description                                          |
| -------------------- | ---------------------------------------------------- |
| `\n`, `\r`, `\t`, `\b` | New line, Carriage return, Horizontal tab, Backspace |
| `\\` | Backslash                                            |
| `\u5154` , `\u{1F600}` | Unicode escape sequence                              |

MoonBit supports string interpolation. It enables you to substitute variables within interpolated strings. This feature simplifies the process of constructing dynamic strings by directly embedding variable values into the text. Variables used for string interpolation must implement the [`Show` trait](/language/methods.md#builtin-traits).

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:dedent:
:start-after: start string 3
:end-before: end string 3
```

```{note}
The interpolated expression can not contain newline, `{}` or `"`.
```

Multi-line strings can be defined using the leading `#|` or `$|`, where the former will keep the raw string and the former will perform the escape and interpolation:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:dedent:
:start-after: start string 4
:end-before: end string 4
```

```{literalinclude} /sources/language/src/builtin/__snapshot__/string_4
:caption: Output
```

The [VSCode extension](/toolchain/vscode/index.md#actions) can help you switch between a plain text and the MoonBit's multiline string.

When the expected type is `String` , the array literal syntax is overloaded to
construct the `String` by specifying each character in the string.

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:dedent:
:start-after: start string 5
:end-before: end string 5
```

```{seealso}
API: <https://mooncakes.io/docs/moonbitlang/core/string>

[Overloaded Literals](overloaded-literals.md)
```

## Char

`Char` represents a Unicode code point.

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:dedent:
:start-after: start char 1
:end-before: end char 1
```

Char literals can be overloaded to type `Int` or `UInt16` when it is the expected type:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:start-after: start char 2
:end-before: end char 2
```

```{seealso}
API: <https://mooncakes.io/docs/moonbitlang/core/char>

[Overloaded Literals](overloaded-literals.md)

```

## Byte(s)

A byte literal in MoonBit is either a single ASCII character or a single escape, have the form of `b'...'`. Byte literals are of type `Byte`. For example:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:start-after: start byte 1
:end-before: end byte 1
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/builtin/__snapshot__/byte_1
:caption: Output
```

A `Bytes` is an immutable sequence of bytes. Similar to byte, bytes literals have the form of `b"..."`. For example:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:start-after: start byte 2
:end-before: end byte 2
```

The byte literal and bytes literal also support escape sequences, but different from those in string literals. The following table lists the supported escape sequences for byte and bytes literals:

| escape sequences     | description                                          |
| -------------------- | ---------------------------------------------------- |
| `\n`, `\r`, `\t`, `\b` | New line, Carriage return, Horizontal tab, Backspace |
| `\\` | Backslash                                            |
| `\x41` | Hexadecimal escape sequence                          |
| `\o102` | Octal escape sequence                                |


``````{note}
You can use `@buffer.T` to construct bytes by writing various types of data. For example:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:start-after: start buffer 1
:end-before: end buffer 1
```

``````

When the expected type is `Bytes`, the `b` prefix can be omitted. Array literals can also be overloaded to construct a `Bytes` sequence by specifying each byte in the sequence.

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:start-after: start bytes 1
:end-before: end bytes 1
```

```{seealso}
API for `Byte`: <https://mooncakes.io/docs/moonbitlang/core/byte>  
API for `Bytes`: <https://mooncakes.io/docs/moonbitlang/core/bytes>  
API for `@buffer.T`: <https://mooncakes.io/docs/moonbitlang/core/buffer>

[Overloaded Literals](overloaded-literals.md)
```

## Tuple

A tuple is a collection of finite values constructed using round brackets `()` with the elements separated by commas `,`. The order of elements matters; for example, `(1,true)` and `(true,1)` have different types. Here's an example:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:start-after: start tuple 1
:end-before: end tuple 1
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/builtin/__snapshot__/tuple_1
:caption: Output
```

Tuples can be accessed via pattern matching or index:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:start-after: start tuple 2
:end-before: end tuple 2
```

## Ref

A `Ref[T]` is a mutable reference containing a value `val` of type `T`.

It can be constructed using `{ val : x }`, and can be accessed using `ref.val`. See [struct](custom-data-types.md#struct) for detailed explanation.

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:start-after: start ref 1
:end-before: end ref 1
```

```{seealso}
API: <https://mooncakes.io/docs/moonbitlang/core/ref>
```

## Option and Result

`Option` and `Result` are the most common types to represent a possible error or failure in MoonBit.

- `Option[T]` represents a possibly missing value of type `T`. It can be abbreviated as `T?`.
- `Result[T, E]` represents either a value of type `T` or an error of type `E`.

See [enum](custom-data-types.md#enum) for detailed explanation.

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:start-after: start option result 1
:end-before: end option result 1
```

```{seealso}
API for `Option`: <https://mooncakes.io/docs/moonbitlang/core/option>  
API for `Result`: <https://mooncakes.io/docs/moonbitlang/core/result>
```

## Array

An array is a finite sequence of values constructed using square brackets `[]`, with elements separated by commas `,`. For example:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:dedent:
:start-after: start array 1
:end-before: end array 1
```

You can use `numbers[x]` to refer to the xth element. The index starts from zero.

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:dedent:
:start-after: start array 2
:end-before: end array 2
```

There are `Array[T]` and `FixedArray[T]`:

`Array[T]` can grow in size, while `FixedArray[T]` has a fixed size, thus it needs to be created with initial value.

``````{warning}
A common pitfall is creating `FixedArray` with the same initial value:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:dedent:
:start-after: start array pitfall
:end-before: end array pitfall
```

This is because all the cells reference to the same object (the `FixedArray[Int]` in this case). One should use `FixedArray::makei()` instead which creates an object for each index.

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:dedent:
:start-after: start array pitfall solution
:end-before: end array pitfall solution
```
``````

When the expected type is known, MoonBit can automatically overload array, otherwise
`Array[T]` is created:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:start-after: start array 3
:end-before: end array 3

```

```{seealso}
API: <https://mooncakes.io/docs/moonbitlang/core/array>

[Overloaded Literals](overloaded-literals.md)
```

### ArrayView

Analogous to `slice` in other languages, the view is a reference to a
specific segment of collections. You can use `data[start:end]` to create a
view of array `data`, referencing elements from `start` to `end` (exclusive).
Both `start` and `end` indices can be omitted.

```{note}
`ArrayView` is an immutable data structure on its own, but the underlying `Array` or `FixedArray`
could be modified.
```

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:start-after: start view 1
:end-before: end view 1
```

```{seealso}
API: <https://mooncakes.io/docs/moonbitlang/core/array>
```

## Map

MoonBit provides a hash map data structure that preserves insertion order called `Map` in its standard library.
`Map`s can be created via a convenient literal syntax:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:start-after: start map 1
:end-before: end map 1
```

Currently keys in map literal syntax must be constant. `Map`s can also be destructed elegantly with pattern matching, see [Map Pattern](pattern-matching.md#map-pattern).

```{seealso}
API: <https://mooncakes.io/docs/moonbitlang/core/builtin#Map>

[Overloaded Literals](overloaded-literals.md)
```

## Json 

MoonBit supports convenient json handling by overloading literals.
When the expected type of an expression is `Json`, number, string, array and map literals can be directly used to create json data:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:start-after: start json 1
:end-before: end json 1
```

Json values can be pattern matched too, see [Json Pattern](pattern-matching.md#json-pattern).

```{seealso}
API: <https://mooncakes.io/docs/moonbitlang/core/json>

[Overloaded Literals](overloaded-literals.md)
```
