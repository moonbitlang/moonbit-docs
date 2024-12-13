# String

A string is a sequence of characters encoded in UTF-16. In MoonBit, strings are immutable, 
which means you cannot change the elements inside a string.

MoonBit supports C-style escape characters in strings and chars, such as `\n`, `\t`, `\\`, `\"`, and `\'`.

Unicode escape characters are also supported. You can use `\u{}` to represent a Unicode character by its code point.

MoonBit also supports string interpolation written like `\{variable}`, which allows you to embed expressions into strings.

