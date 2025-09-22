# String

A string is a sequence of characters encoded in UTF-16. In MoonBit, strings are immutable,
which means you cannot change the elements inside a string.

MoonBit supports C-style escape characters in strings and chars, such as `\n` (newline),
`\t` (tab), `\\` (backslash), `\"` (double-quote), and `\'` (single-quote).

Unicode escape characters are also supported. You can use `\u{...}` (where `...` represents
the Unicode character's hex code) to represent a Unicode character by its code point.

MoonBit also supports string interpolation written like `\{variable}`, which allows you to embed expressions into strings.

