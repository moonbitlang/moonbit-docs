# Lexical Conventions

This page specifies MoonBit lexical forms. Runtime representation, APIs, and
literal overloading are covered in
[Fundamentals](https://docs.moonbitlang.com/en/latest/language/fundamentals.html#built-in-data-structures).

MoonBit source text must be well-formed UTF-8. Malformed input reports a
lexical error. At each position, the lexer consumes the longest valid token.
Whitespace is discarded, while newlines participate in automatic semicolon
insertion.

In the productions, `{ symbol }` means zero or more repetitions,
`{ symbol }+` means one or more repetitions, `[ symbol ]` means zero or one
occurrence, and `x...y` denotes an inclusive range. Parentheses group a form.
An `except` clause removes the listed forms from the complete form on its left.

## Common Lexical Classes

```
**unicode-scalar-value** ::= U+0000...U+D7FF | U+E000...U+10FFFF

**newline-character** ::= LF | CR | U+2028 | U+2029

**newline** ::= [*newline-character*](#grammar-token-moonbit-lexical-newline-character) | CR LF

**whitespace** ::= U+0009 | U+000B | U+000C | U+0020 | U+00A0 | U+1680
             | U+2000...U+200A | U+202F | U+205F | U+3000 | U+FEFF

**line-character** ::= [*unicode-scalar-value*](#grammar-token-moonbit-lexical-unicode-scalar-value) except [*newline-character*](#grammar-token-moonbit-lexical-newline-character)
```

## String Literals

```
**string-literal** ::= " { [*string-character*](#grammar-token-moonbit-lexical-string-character) } "

**string-character** ::= [*regular-string-character*](#grammar-token-moonbit-lexical-regular-string-character)
                   | [*simple-escape-sequence*](#grammar-token-moonbit-lexical-simple-escape-sequence)
                   | [*unicode-escape-sequence*](#grammar-token-moonbit-lexical-unicode-escape-sequence)
                   | [*interpolation*](#grammar-token-moonbit-lexical-interpolation)

**regular-string-character** ::= [*unicode-scalar-value*](#grammar-token-moonbit-lexical-unicode-scalar-value)
                             except ", \, and [*newline-character*](#grammar-token-moonbit-lexical-newline-character)

**simple-escape-sequence** ::= \ (\ | " | ' | n | t | b | r | f | /)

**unicode-escape-sequence** ::= \u (0...9 | A...F | a...f) (0...9 | A...F | a...f)
                            (0...9 | A...F | a...f) (0...9 | A...F | a...f)
                          | \u{ { 0...9 | A...F | a...f }+ }
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

A Unicode escape must denote a Unicode scalar value. A newline before the
closing quote reports an unterminated string literal.

### Interpolation

```
**interpolation** ::= \{ { [*whitespace*](#grammar-token-moonbit-lexical-whitespace) } *expression* { [*whitespace*](#grammar-token-moonbit-lexical-whitespace) } }
```

The expression must be nonempty and end at the matching `}`. Braces inside
nested literals do not affect matching. Nested interpolations are recognized
recursively. Newlines, `//` comments, attributes, and multiline string literals
are not permitted.

## Multiline String Literals

```
**multiline-string-literal** ::= [*multiline-string-line*](#grammar-token-moonbit-lexical-multiline-string-line)
                           { [*newline*](#grammar-token-moonbit-lexical-newline) [*multiline-string-line*](#grammar-token-moonbit-lexical-multiline-string-line) }

**multiline-string-line** ::= [*raw-multiline-string-line*](#grammar-token-moonbit-lexical-raw-multiline-string-line)
                        | [*interpolated-multiline-string-line*](#grammar-token-moonbit-lexical-interpolated-multiline-string-line)

**raw-multiline-string-line** ::= #| { [*multiline-regular-character*](#grammar-token-moonbit-lexical-multiline-regular-character) }

**interpolated-multiline-string-line** ::= $| { [*multiline-regular-character*](#grammar-token-moonbit-lexical-multiline-regular-character) | [*interpolation*](#grammar-token-moonbit-lexical-interpolation) }

**multiline-regular-character** ::= [*unicode-scalar-value*](#grammar-token-moonbit-lexical-unicode-scalar-value)
                                except [*newline-character*](#grammar-token-moonbit-lexical-newline-character)
```

The prefixes are omitted from the result, and lines are joined with U+000A. A
final empty prefixed line adds a trailing line feed. A `#|` line is literal. In
a `$|` line, only `\{` begins interpolation. Multiline strings are not permitted
inside interpolation expressions.

## Bytes Literals

```
**bytes-literal** ::= b" { [*bytes-character*](#grammar-token-moonbit-lexical-bytes-character) } "

**bytes-character** ::= [*regular-string-character*](#grammar-token-moonbit-lexical-regular-string-character)
                  | [*simple-escape-sequence*](#grammar-token-moonbit-lexical-simple-escape-sequence)
                  | [*byte-escape-sequence*](#grammar-token-moonbit-lexical-byte-escape-sequence)
                  | [*interpolation*](#grammar-token-moonbit-lexical-interpolation)

**byte-escape-sequence** ::= \x (0...9 | A...F | a...f) (0...9 | A...F | a...f)
                       | \o (0...3) (0...7) (0...7)
```

A newline before the closing quote reports an unterminated literal. Non-ASCII
source characters contribute their UTF-8 encoding. `\xHH` and `\oDDD` each
contribute one byte with a value from 0 to 255. Interpolation follows the
string-literal rules. There is no multiline bytes-literal form.

## Regex Literals

```
**regex-literal** ::= re" { [*regex-character*](#grammar-token-moonbit-lexical-regex-character) } "

**regex-character** ::= [*regular-string-character*](#grammar-token-moonbit-lexical-regular-string-character)
                  | \ ([*unicode-scalar-value*](#grammar-token-moonbit-lexical-unicode-scalar-value) except { and [*newline-character*](#grammar-token-moonbit-lexical-newline-character))
                  | [*interpolation*](#grammar-token-moonbit-lexical-interpolation)
```

Backslashes are preserved for the regex parser, while `\{` starts an
interpolation. Interpolated regex literals are accepted only in lex-pattern
contexts. A newline before the closing quote reports an unterminated literal.
See [Regex Literal Expression](https://docs.moonbitlang.com/en/latest/language/fundamentals.html#regex-literal-expression).

## Character Literals

```
**character-literal** ::= ' [*regular-character*](#grammar-token-moonbit-lexical-regular-character) '
                    | ' [*character-escape-sequence*](#grammar-token-moonbit-lexical-character-escape-sequence) '

**regular-character** ::= [*unicode-scalar-value*](#grammar-token-moonbit-lexical-unicode-scalar-value)
                      except ', \, and [*newline-character*](#grammar-token-moonbit-lexical-newline-character)

**character-escape-sequence** ::= [*simple-escape-sequence*](#grammar-token-moonbit-lexical-simple-escape-sequence)
                            | [*unicode-escape-sequence*](#grammar-token-moonbit-lexical-unicode-escape-sequence)
```

A character literal contains exactly one Unicode scalar value or escape
sequence.

## Byte Literals

```
**byte-literal** ::= b' [*regular-byte-character*](#grammar-token-moonbit-lexical-regular-byte-character) '
               | b' [*byte-character-escape-sequence*](#grammar-token-moonbit-lexical-byte-character-escape-sequence) '

**regular-byte-character** ::= (U+0000...U+007F)
                           except ', \, and [*newline-character*](#grammar-token-moonbit-lexical-newline-character)

**byte-character-escape-sequence** ::= [*simple-escape-sequence*](#grammar-token-moonbit-lexical-simple-escape-sequence)
                                 | [*byte-escape-sequence*](#grammar-token-moonbit-lexical-byte-escape-sequence)
```

An unescaped byte is ASCII. Unicode escapes are invalid in byte literals.

## Comments

```
**doc-comment** ::= /// { [*line-character*](#grammar-token-moonbit-lexical-line-character) }

**line-comment** ::= // { [*line-character*](#grammar-token-moonbit-lexical-line-character) }
```

`doc-comment` takes precedence over `line-comment` when both match. MoonBit has
no block-comment form.

## Identifiers

```
**non-ascii** ::= U+00A1...U+00AC
              | U+00AE...U+02AF
              | U+1100...U+11FF
              | U+1E00...U+1EFF
              | U+2070...U+209F
              | U+2150...U+218F
              | U+2E80...U+2EFF
              | U+2FF0...U+2FFF
              | U+3001...U+30FF
              | U+31C0...U+9FFF
              | U+AC00...U+D7FF
              | U+F900...U+FAFF
              | U+FE00...U+FE0F
              | U+FE30...U+FE4F
              | U+1F000...U+1FBFF
              | U+20000...U+2A6DF
              | U+2A700...U+2EBEF
              | U+2F800...U+2FA1F
              | U+30000...U+323AF
              | U+E0100...U+E01EF

**uident** ::= (A...Z) { A...Z | a...z | 0...9 | _ | [*non-ascii*](#grammar-token-moonbit-lexical-non-ascii) }

**lident** ::= _ { A...Z | a...z | 0...9 | _ | [*non-ascii*](#grammar-token-moonbit-lexical-non-ascii) }+
         | (a...z | [*non-ascii*](#grammar-token-moonbit-lexical-non-ascii)) { A...Z | a...z | 0...9 | _ | [*non-ascii*](#grammar-token-moonbit-lexical-non-ascii) }

**underscore** ::= _
```

These exact ranges are used, without Unicode normalization. A `uident` begins
with an ASCII uppercase letter. All other identifier spellings begin with an
ASCII lowercase letter, `_`, or a character in `non-ascii`. The exact spelling
`_` is a dedicated token. Keywords also use their own tokens. A leading ASCII
decimal digit starts a numeric literal.

### Keywords

```
**keyword** ::= as | else | extern | fn | if | let
          | const | match | using | mut | type
          | struct | enum | extenum | trait
          | derive | while | break | continue | import | return
          | throw | raise | try | catch | pub | priv
          | proof_assert | proof_let | readonly | true | false
          | test | loop | for | in | impl | with
          | guard | async | is | suberror | and | letrec
          | enumview | noraise | nocancel | defer | lexscan
          | where | declare | nobreak | extend | try! | guard!
```

Keywords take precedence over identifiers.

The following spellings are reserved. A spelling that is not already a keyword
is otherwise tokenized as an identifier or label and reports a
reserved-keyword warning.

```
**reserved-word** ::= module | move | ref | static | super | unsafe
                | use | await | dyn | abstract | do | final
                | macro | override | typeof | virtual | yield
                | local | method | alias | assert | package
                | recur | isnot | define
                | downcast | inherit | member | namespace | upcast
                | void | lazy | include | mixin | protected
                | sealed | constructor | atomic | volatile
                | anyframe | anytype | asm | comptime | errdefer
                | export | opaque | orelse | resume | threadlocal
                | unreachable | dynclass | dynobj | dynrec | var
                | finally | noasync | assume
```

### Labels

```
**label** ::= _ { A...Z | a...z | 0...9 | _ | [*non-ascii*](#grammar-token-moonbit-lexical-non-ascii) }+ ~
        | ((a...z | [*non-ascii*](#grammar-token-moonbit-lexical-non-ascii)) { A...Z | a...z | 0...9 | _ | [*non-ascii*](#grammar-token-moonbit-lexical-non-ascii) } ~) except [*keyword*](#grammar-token-moonbit-lexical-keyword)~
```

The `~` must immediately follow the name. ASCII-uppercase identifiers and
keywords cannot form labels.

## Package Names

```
**package-part** ::= (A...Z | a...z | _) { A...Z | a...z | 0...9 | _ | - }

**package-name** ::= @ [*package-part*](#grammar-token-moonbit-lexical-package-part) { / [*package-part*](#grammar-token-moonbit-lexical-package-part) }
```

Package names are ASCII-only. A hyphen cannot begin a package part. The leading
`@`, slashes, and parts must be adjacent.

## Attributes

```
**attribute-name** ::= (A...Z | a...z | _) { A...Z | a...z | 0...9 | _ }

**attribute** ::= # [*attribute-name*](#grammar-token-moonbit-lexical-attribute-name) [ . [*attribute-name*](#grammar-token-moonbit-lexical-attribute-name) ] { [*line-character*](#grammar-token-moonbit-lexical-line-character) }
```

After the optional dot-qualified name, everything through the next newline is
the raw payload. Attributes are not permitted inside an `interpolation`. See
[Attribute](https://docs.moonbitlang.com/en/latest/language/attributes.html) for the payload grammar.

## Numeric Literals

```
**integer-nums** ::= (0...9) { 0...9 | _ }
               | 0 (x | X) (0...9 | A...F | a...f) { 0...9 | A...F | a...f | _ }
               | 0 (o | O) (0...7) { 0...7 | _ }
               | 0 (b | B) (0 | 1) { 0 | 1 | _ }

**integer-literal** ::= [*integer-nums*](#grammar-token-moonbit-lexical-integer-nums) [ UL | U | L | N ]

**double-dec** ::= (0...9) { 0...9 | _ } . { 0...9 | _ }
               [ (e | E) [ + | - ] (0...9) { 0...9 | _ } ]

**double-hex** ::= 0 (x | X) (0...9 | A...F | a...f)
               { 0...9 | A...F | a...f | _ } .
               { 0...9 | A...F | a...f | _ }
               [ (p | P) [ + | - ] (0...9) { 0...9 | _ } ]

**double-literal** ::= [*double-dec*](#grammar-token-moonbit-lexical-double-dec) | [*double-hex*](#grammar-token-moonbit-lexical-double-hex)

**float-dec** ::= [*double-dec*](#grammar-token-moonbit-lexical-double-dec) F

**float-hex** ::= 0 (x | X) (0...9 | A...F | a...f)
              { 0...9 | A...F | a...f | _ } .
              { 0...9 | A...F | a...f | _ }
              (p | P) [ + | - ] (0...9) { 0...9 | _ } F

**float-literal** ::= [*float-dec*](#grammar-token-moonbit-lexical-float-dec) | [*float-hex*](#grammar-token-moonbit-lexical-float-hex)
```

After the first digit of a numeral, underscores may repeat or trail. Uppercase
suffixes select `UInt` (`U`), `Int64` (`L`), `UInt64` (`UL`), `BigInt` (`N`),
or `Float` (`F`). An unsuffixed floating-point literal is a `Double`.

Floating-point literals always contain a decimal point. A hexadecimal `Float`
requires a `p` or `P` exponent before `F`, so `0x1.F` is a `Double`. Signs are
separate tokens. Before `..`, an integer ends first, so `1..=2` begins
with `1` and `..=`.

`1.` and `1.F` are also valid double and float literal.

## Dot-Prefixed Tokens

```
**tuple-accessor** ::= . { 0...9 }+

**dot-identifier** ::= . (A...Z | a...z | _ | [*non-ascii*](#grammar-token-moonbit-lexical-non-ascii)) { A...Z | a...z | 0...9 | _ | [*non-ascii*](#grammar-token-moonbit-lexical-non-ascii) }
```

These forms contain no whitespace. Tuple accessors do not permit underscores,
and dot-identifiers use the identifier case rules without consulting the
keyword table, so `.if` is valid. A single `.` reports a lexical error.

## Operators and Delimiters

```
**delimiter** ::= ( | ) | , | :: | : | ;
            | [ | ] | { | } | [| | |]

**operator** ::= => | ->
           | && | & | ^
           | * | / | %
           | << | >>
           | = | > | <| | <? | <+ | <
           | == | != | =~ | <= | >=
           | | | || | + | - | ? | !
           | += | -= | *= | /= | %= | |>
           | .. | ..= | ..< | ..<= | >.. | >=.. | ...
```

The longest listed token wins. MoonBit has no generic operator-name syntax.

## Automatic Semicolon Insertion

After a newline, the lexer may insert `;` when the preceding token can end a
statement and the following token can begin one. End of file is also an
eligible follower. It does not insert one before `}` or between adjacent
multiline string lines.

## `.mbti` Extensions

The `.mbti` lexical grammar adds this keyword to `.mbt`:

```
**mbti-keyword** ::= [*keyword*](#grammar-token-moonbit-lexical-keyword) | package
```

In `.mbti`, `package` takes precedence over identifiers and cannot form a
label. In `.mbt`, it follows the reserved-word behavior above and can
form `package~`.
