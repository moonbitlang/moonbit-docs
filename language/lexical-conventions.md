# Lexical Conventions

#### WARNING
This page is a work in progress and is currently incomplete.

This page specifies MoonBit lexical forms. Runtime representation, APIs, and
literal overloading are covered in
[Fundamentals](fundamentals.md#built-in-data-structures).

In the productions, `{ symbol }` means zero or more repetitions,
`{ symbol }+` means one or more repetitions, and `x ... y` denotes an inclusive
range.

## Common Lexical Classes

```
**hex-digit** ::= 0 ... 9 | A ... F | a ... f

**octal-digit** ::= 0 ... 7

**unicode-scalar-value** ::= U+0000 ... U+D7FF | U+E000 ... U+10FFFF

**newline** ::= LF | CR | CR LF | U+2028 | U+2029

**whitespace** ::= U+0009 | U+000B | U+000C | U+0020 | U+00A0 | U+1680
             | U+2000 ... U+200A | U+202F | U+205F | U+3000 | U+FEFF
```

## String Literals

```
**string-literal** ::= " { [*string-character*](#grammar-token-moonbit-lexical-string-character) } "

**string-character** ::= [*regular-string-character*](#grammar-token-moonbit-lexical-regular-string-character)
                   | [*simple-escape-sequence*](#grammar-token-moonbit-lexical-simple-escape-sequence)
                   | [*unicode-escape-sequence*](#grammar-token-moonbit-lexical-unicode-escape-sequence)
                   | [*interpolation*](#grammar-token-moonbit-lexical-interpolation)

**regular-string-character** ::= [*unicode-scalar-value*](#grammar-token-moonbit-lexical-unicode-scalar-value) except ", \, CR, and LF

**simple-escape-sequence** ::= \ (\ | " | ' | n | t | b | r | f | /)

**unicode-escape-sequence** ::= \u [*hex-digit*](#grammar-token-moonbit-lexical-hex-digit) [*hex-digit*](#grammar-token-moonbit-lexical-hex-digit) [*hex-digit*](#grammar-token-moonbit-lexical-hex-digit) [*hex-digit*](#grammar-token-moonbit-lexical-hex-digit)
                          | \u{ { [*hex-digit*](#grammar-token-moonbit-lexical-hex-digit) }+ }
```

The simple escape sequences have the following meanings:

| Sequence   | Character                |
|------------|--------------------------|
| `\\`       | Backslash (U+005C)       |
| `\"`       | Double quote (U+0022)    |
| `\'`       | Single quote (U+0027)    |
| `\/`       | Forward slash (U+002F)   |
| `\n`       | Line feed (U+000A)       |
| `\r`       | Carriage return (U+000D) |
| `\t`       | Horizontal tab (U+0009)  |
| `\b`       | Backspace (U+0008)       |
| `\f`       | Form feed (U+000C)       |

A Unicode escape must denote a Unicode scalar value. A CR or LF before the
closing quote reports an unterminated string literal.

### Interpolation

```
**interpolation** ::= \{ { [*whitespace*](#grammar-token-moonbit-lexical-whitespace) } *expression* { [*whitespace*](#grammar-token-moonbit-lexical-whitespace) } }
```

The expression must be nonempty and end at the matching `}`. Braces inside
nested literals do not affect matching; nested interpolations are recognized
recursively. CR, LF, `//` comments, attributes, and multiline string literals
are not permitted.

## Multiline String Literals

```
**multiline-string-literal** ::= [*raw-multiline-string-literal*](#grammar-token-moonbit-lexical-raw-multiline-string-literal)
                           | [*interpolated-multiline-string-literal*](#grammar-token-moonbit-lexical-interpolated-multiline-string-literal)

**raw-multiline-string-literal** ::= [*raw-multiline-string-line*](#grammar-token-moonbit-lexical-raw-multiline-string-line)
                               { [*newline*](#grammar-token-moonbit-lexical-newline) [*raw-multiline-string-line*](#grammar-token-moonbit-lexical-raw-multiline-string-line) }

**interpolated-multiline-string-literal** ::= [*interpolated-multiline-string-line*](#grammar-token-moonbit-lexical-interpolated-multiline-string-line)
                                        { [*newline*](#grammar-token-moonbit-lexical-newline) [*interpolated-multiline-string-line*](#grammar-token-moonbit-lexical-interpolated-multiline-string-line) }

**raw-multiline-string-line** ::= #| { [*multiline-regular-character*](#grammar-token-moonbit-lexical-multiline-regular-character) }

**interpolated-multiline-string-line** ::= $| { [*multiline-regular-character*](#grammar-token-moonbit-lexical-multiline-regular-character) | [*interpolation*](#grammar-token-moonbit-lexical-interpolation) }

**multiline-regular-character** ::= [*unicode-scalar-value*](#grammar-token-moonbit-lexical-unicode-scalar-value) except CR and LF
```

The prefixes are omitted from the result, and lines are joined with U+000A. A
final empty prefixed line adds a trailing line feed. A `#|` line is literal; in
a `$|` line, only `\{` begins interpolation. Multiline strings are not permitted
inside interpolation expressions.

## Bytes Literals

```
**bytes-literal** ::= b" { [*bytes-character*](#grammar-token-moonbit-lexical-bytes-character) } "

**bytes-character** ::= [*regular-string-character*](#grammar-token-moonbit-lexical-regular-string-character)
                  | [*simple-escape-sequence*](#grammar-token-moonbit-lexical-simple-escape-sequence)
                  | [*byte-escape-sequence*](#grammar-token-moonbit-lexical-byte-escape-sequence)
                  | [*interpolation*](#grammar-token-moonbit-lexical-interpolation)

**byte-escape-sequence** ::= \x [*hex-digit*](#grammar-token-moonbit-lexical-hex-digit) [*hex-digit*](#grammar-token-moonbit-lexical-hex-digit)
                       | \o (0 ... 3) [*octal-digit*](#grammar-token-moonbit-lexical-octal-digit) [*octal-digit*](#grammar-token-moonbit-lexical-octal-digit)
```

A CR or LF before the closing quote reports an unterminated literal. Non-ASCII
source characters contribute their UTF-8 encoding; `\xHH` and `\oDDD` each
contribute one byte with a value from 0 to 255. Interpolation follows the
string-literal rules. There is no multiline bytes-literal form.

## Character Literals

```
**character-literal** ::= ' [*regular-character*](#grammar-token-moonbit-lexical-regular-character) '
                    | ' [*character-escape-sequence*](#grammar-token-moonbit-lexical-character-escape-sequence) '

**regular-character** ::= [*unicode-scalar-value*](#grammar-token-moonbit-lexical-unicode-scalar-value) except ', \, CR, and LF

**character-escape-sequence** ::= [*simple-escape-sequence*](#grammar-token-moonbit-lexical-simple-escape-sequence)
                            | [*unicode-escape-sequence*](#grammar-token-moonbit-lexical-unicode-escape-sequence)
```

A character literal contains exactly one Unicode scalar value or escape
sequence.

## Byte Literals

```
**byte-literal** ::= b' [*regular-byte-character*](#grammar-token-moonbit-lexical-regular-byte-character) '
               | b' [*byte-character-escape-sequence*](#grammar-token-moonbit-lexical-byte-character-escape-sequence) '

**regular-byte-character** ::= U+0000 ... U+007F except ', \, CR, and LF

**byte-character-escape-sequence** ::= [*simple-escape-sequence*](#grammar-token-moonbit-lexical-simple-escape-sequence)
                                 | [*byte-escape-sequence*](#grammar-token-moonbit-lexical-byte-escape-sequence)
```

An unescaped byte is ASCII. Unicode escapes are invalid in byte literals.
