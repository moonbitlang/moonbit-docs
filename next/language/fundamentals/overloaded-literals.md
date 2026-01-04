# Overloaded Literals

Overloaded literals allow you to use the same syntax to represent different types of values. 
For example, you can use `1` to represent `UInt` or `Double` depending on the expected type. If the expected type is not known, the literal will be interpreted as `Int` by default.

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:start-after: start overloaded literal 1
:end-before: end overloaded literal 1
```

The overloaded literals can be composed. If array literal can be overloaded to `Bytes` , and number literal can be overloaded to `Byte` , then you can overload `[1,2,3]` to `Bytes` as well. Here is a table of overloaded literals in MoonBit:

| Overloaded literal             | Default type | Can be overloaded to                                                                      | 
| ------------------------------ | ------------ | ----------------------------------------------------------------------------------------- |
| `10`, `0xFF`, `0o377`, `10_000` | `Int` | `UInt`, `Int64`, `UInt64`, `Int16`, `UInt16`, `Byte`, `Double`, `Float`, `BigInt` |
| `"str"` | `String` | `Bytes` |
| `'c'` | `Char` | `Int` , `Byte` |
| `3.14` | `Double` | `Float` |
| `[a, b, c]` (where the types of literals a, b, and c are E) | `Array[E]` | `FixedArray[E]`, `String`  (if E is of type Char), `Bytes` (if E is of type Byte) |

There are also some similar overloading rules in pattern. For more details, see [Pattern Matching](pattern-matching.md).

```{note}
Literal overloading is not the same as value conversion. To convert a variable to a different type, you can use methods prefixed with `to_`, such as `to_int()`, `to_double()`, etc.

```

## Escape Sequences in Overloaded Literals

Escape sequences can be used in overloaded `"..."` literals and `'...'` literals. The interpretation of escape sequences depends on the types they are overloaded to:

- Simple escape sequences

  Including `\n`, `\r`, `\t`, `\\`, and `\b`. These escape sequences are supported in any `"..."` or `'...'` literals. They are interpreted as their respective `Char` or `Byte` in `String` or `Bytes`.

- Byte escape sequences 

  The `\x41` and `\o102` escape sequences represent a Byte. These are supported in literals overloaded to `Bytes` and `Byte`. 

- Unicode escape sequences

  The `\u5154` and `\u{1F600}` escape sequences represent a `Char`. These are supported in literals of type `String` and `Char`.
