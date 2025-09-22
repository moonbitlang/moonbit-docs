# Literals and Types

Syntax constructs such as `42`, `3.14`, `0xFF`, and `false` are known as **literals**. Literals provide a straightforward way to represent fixed values directly in code.

## Basic Types

MoonBit provides various basic data types, with their corresponding literal representations:

| Type     | Literal Example | Description                        |
| -------- | --------------- | ---------------------------------- |
| `Int` | `42` | 32-bit signed integer              |
| `Double` | `3.14` | Double-precision floating point    |
| `Bool` | `true`, `false` | Boolean value, true or false       |  
| `Char` | `'a'` | Single Unicode character           |
| `String` | `"hello"` | String, composed of zero or more characters |
| `Unit`   | `()`      | A special type with a single value, typically used to indicate the absence of a meaningful return value from a function |

## Different Representations of Integer Literals

Integers can be represented in multiple number bases. MoonBit supports:

* **Decimal**: `1000000` or `1_000_000` (underscore separators for readability)
* **Hexadecimal**: `0xFFFF` (prefixed with `0x`)
* **Octal**: `0o777` (prefixed with `0o`)
* **Binary**: `0b1010` (prefixed with `0b`)

## Arithmetic Operations

This example demonstrates basic arithmetic operators and the use of different numeric types.
