# String And Char

[`String`](https://mooncakes.io/docs/moonbitlang/core/string) is a sequence of character encoded in UTF-16. In MoonBit, strings are immutable, which means you cannot change the elements inside a string. 

[`Char`](https://mooncakes.io/docs/moonbitlang/core/char) is a single Unicode character, represented by a single quote, for example `'a'`.

## Escape sequences and Unicode

To represent special characters, MoonBit supports C-style escape sequences in string and char literals, such as `\n` (newline), `\t` (tab), `\\` (backslash), `\"` (double quote), and `\'` (single quote).

Unicode escape characters are also supported. You can use `\u{...}` (where `...` represents the Unicode character's hex code) to represent a Unicode character by its code point.

## String interpolation and concatenation

MoonBit also supports string interpolation, written as `\{variable}`, which allows you to embed expressions into strings. You can also concatenate strings using the `+` operator.

`String` is a complex type in real-world programs. This lesson introduces the basics, but there are many advanced features that will be covered later.

