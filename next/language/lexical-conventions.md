# Lexical Conventions

This page specifies MoonBit lexical forms. Runtime representation, APIs, and
literal overloading are covered in
[Fundamentals](fundamentals.md#built-in-data-structures).

MoonBit source text must be well-formed UTF-8. Malformed input reports a
lexical error. At each position, the lexer consumes the longest valid token.
Whitespace is discarded, while newlines participate in automatic semicolon
insertion.

In the productions, `{ symbol }` means zero or more repetitions,
`{ symbol }+` means one or more repetitions, `[ symbol ]` means zero or one
occurrence, and `x...y` denotes an inclusive range. Parentheses group a form.
An `except` clause removes the listed forms from the complete form on its left.

## Common Lexical Classes

```{moonbit-grammar} moonbit-lexical
unicode-scalar-value ::= "U+0000"..."U+D7FF" | "U+E000"..."U+10FFFF"

newline-character ::= "LF" | "CR" | "U+2028" | "U+2029"

newline ::= `newline-character` | "CR" "LF"

whitespace ::= "U+0009" | "U+000B" | "U+000C" | "U+0020" | "U+00A0" | "U+1680"
             | "U+2000"..."U+200A" | "U+202F" | "U+205F" | "U+3000" | "U+FEFF"

line-character ::= `unicode-scalar-value` except `newline-character`
```

## String Literals

```{moonbit-grammar} moonbit-lexical
string-literal ::= "\"" { `string-character` } "\""

string-character ::= `regular-string-character`
                   | `simple-escape-sequence`
                   | `unicode-escape-sequence`
                   | `interpolation`

regular-string-character ::= `unicode-scalar-value`
                             except "\"", "\\", and `newline-character`

simple-escape-sequence ::= "\\" ("\\" | "\"" | "'" | "n" | "t" | "b" | "r" | "f" | "/")

unicode-escape-sequence ::= "\\u" ("0"..."9" | "A"..."F" | "a"..."f") ("0"..."9" | "A"..."F" | "a"..."f")
                            ("0"..."9" | "A"..."F" | "a"..."f") ("0"..."9" | "A"..."F" | "a"..."f")
                          | "\\u{" { "0"..."9" | "A"..."F" | "a"..."f" }+ "}"
```

The simple escape sequences have the following meanings:

| Sequence | Character |
| --- | --- |
| `\\` | Backslash (U+005C) |
| `\"` | Double quote (U+0022) |
| `\'` | Single quote (U+0027) |
| `\/` | Forward slash (U+002F) |
| `\n` | Line feed (U+000A) |
| `\r` | Carriage return (U+000D) |
| `\t` | Horizontal tab (U+0009) |
| `\b` | Backspace (U+0008) |
| `\f` | Form feed (U+000C) |

A Unicode escape must denote a Unicode scalar value. A newline before the
closing quote reports an unterminated string literal.

### Interpolation

```{moonbit-grammar} moonbit-lexical
interpolation ::= "\\{" { `whitespace` } `expression` { `whitespace` } "}"
```

The expression must be nonempty and end at the matching `}`. Braces inside
nested literals do not affect matching. Nested interpolations are recognized
recursively. Newlines, `//` comments, attributes, and multiline string literals
are not permitted.

## Multiline String Literals

```{moonbit-grammar} moonbit-lexical
multiline-string-literal ::= `multiline-string-line`
                           { `newline` `multiline-string-line` }

multiline-string-line ::= `raw-multiline-string-line`
                        | `interpolated-multiline-string-line`

raw-multiline-string-line ::= "#|" { `multiline-regular-character` }

interpolated-multiline-string-line ::= "$|" { `multiline-regular-character` | `interpolation` }

multiline-regular-character ::= `unicode-scalar-value`
                                except `newline-character`
```

The prefixes are omitted from the result, and lines are joined with U+000A. A
final empty prefixed line adds a trailing line feed. A `#|` line is literal. In
a `$|` line, only `\{` begins interpolation. Multiline strings are not permitted
inside interpolation expressions.

## Bytes Literals

```{moonbit-grammar} moonbit-lexical
bytes-literal ::= "b\"" { `bytes-character` } "\""

bytes-character ::= `regular-string-character`
                  | `simple-escape-sequence`
                  | `byte-escape-sequence`
                  | `interpolation`

byte-escape-sequence ::= "\\x" ("0"..."9" | "A"..."F" | "a"..."f") ("0"..."9" | "A"..."F" | "a"..."f")
                       | "\\o" ("0"..."3") ("0"..."7") ("0"..."7")
```

A newline before the closing quote reports an unterminated literal. Non-ASCII
source characters contribute their UTF-8 encoding. `\xHH` and `\oDDD` each
contribute one byte with a value from 0 to 255. Interpolation follows the
string-literal rules. There is no multiline bytes-literal form.

## Regex Literals

```{moonbit-grammar} moonbit-lexical
regex-literal ::= "re\"" { `regex-character` } "\""

regex-character ::= `regular-string-character`
                  | "\\" (`unicode-scalar-value` except "{" and `newline-character`)
                  | `interpolation`
```

Backslashes are preserved for the regex parser, while `\{` starts an
interpolation. Interpolated regex literals are accepted only in lex-pattern
contexts. A newline before the closing quote reports an unterminated literal.
See [Regex Literal Expression](fundamentals.md#regex-literal-expression).

## Character Literals

```{moonbit-grammar} moonbit-lexical
character-literal ::= "'" `regular-character` "'"
                    | "'" `character-escape-sequence` "'"

regular-character ::= `unicode-scalar-value`
                      except "'", "\\", and `newline-character`

character-escape-sequence ::= `simple-escape-sequence`
                            | `unicode-escape-sequence`
```

A character literal contains exactly one Unicode scalar value or escape
sequence.

## Byte Literals

```{moonbit-grammar} moonbit-lexical
byte-literal ::= "b'" `regular-byte-character` "'"
               | "b'" `byte-character-escape-sequence` "'"

regular-byte-character ::= ("U+0000"..."U+007F")
                           except "'", "\\", and `newline-character`

byte-character-escape-sequence ::= `simple-escape-sequence`
                                 | `byte-escape-sequence`
```

An unescaped byte is ASCII. Unicode escapes are invalid in byte literals.

## Comments

```{moonbit-grammar} moonbit-lexical
doc-comment ::= "///" { `line-character` }

line-comment ::= "//" { `line-character` }
```

`doc-comment` takes precedence over `line-comment` when both match. MoonBit has
no block-comment form.

## Identifiers

```{moonbit-grammar} moonbit-lexical
non-ascii ::= "U+00A1"..."U+00AC"
              | "U+00AE"..."U+02AF"
              | "U+1100"..."U+11FF"
              | "U+1E00"..."U+1EFF"
              | "U+2070"..."U+209F"
              | "U+2150"..."U+218F"
              | "U+2E80"..."U+2EFF"
              | "U+2FF0"..."U+2FFF"
              | "U+3001"..."U+30FF"
              | "U+31C0"..."U+9FFF"
              | "U+AC00"..."U+D7FF"
              | "U+F900"..."U+FAFF"
              | "U+FE00"..."U+FE0F"
              | "U+FE30"..."U+FE4F"
              | "U+1F000"..."U+1FBFF"
              | "U+20000"..."U+2A6DF"
              | "U+2A700"..."U+2EBEF"
              | "U+2F800"..."U+2FA1F"
              | "U+30000"..."U+323AF"
              | "U+E0100"..."U+E01EF"

uident ::= ("A"..."Z") { "A"..."Z" | "a"..."z" | "0"..."9" | "_" | `non-ascii` }

lident ::= "_" { "A"..."Z" | "a"..."z" | "0"..."9" | "_" | `non-ascii` }+
         | ("a"..."z" | `non-ascii`) { "A"..."Z" | "a"..."z" | "0"..."9" | "_" | `non-ascii` }

underscore ::= "_"
```

These exact ranges are used, without Unicode normalization. A `uident` begins
with an ASCII uppercase letter. All other identifier spellings begin with an
ASCII lowercase letter, `_`, or a character in `non-ascii`. The exact spelling
`_` is a dedicated token. Keywords also use their own tokens. A leading ASCII
decimal digit starts a numeric literal.

### Keywords

```{moonbit-grammar} moonbit-lexical
keyword ::= "as" | "else" | "extern" | "fn" | "if" | "let"
          | "const" | "match" | "using" | "mut" | "type"
          | "struct" | "enum" | "extenum" | "trait"
          | "derive" | "while" | "break" | "continue" | "import" | "return"
          | "throw" | "raise" | "try" | "catch" | "pub" | "priv"
          | "proof_assert" | "proof_let" | "readonly" | "true" | "false"
          | "test" | "loop" | "for" | "in" | "impl" | "with"
          | "guard" | "async" | "is" | "suberror" | "and" | "letrec"
          | "enumview" | "noraise" | "nocancel" | "defer" | "lexscan"
          | "where" | "declare" | "nobreak" | "extend" | "try!" | "guard!"
```

Keywords take precedence over identifiers.

The following spellings are reserved. A spelling that is not already a keyword
is otherwise tokenized as an identifier or label and reports a
reserved-keyword warning.

```{moonbit-grammar} moonbit-lexical
reserved-word ::= "module" | "move" | "ref" | "static" | "super" | "unsafe"
                | "use" | "await" | "dyn" | "abstract" | "do" | "final"
                | "macro" | "override" | "typeof" | "virtual" | "yield"
                | "local" | "method" | "alias" | "assert" | "package"
                | "recur" | "isnot" | "define"
                | "downcast" | "inherit" | "member" | "namespace" | "upcast"
                | "void" | "lazy" | "include" | "mixin" | "protected"
                | "sealed" | "constructor" | "atomic" | "volatile"
                | "anyframe" | "anytype" | "asm" | "comptime" | "errdefer"
                | "export" | "opaque" | "orelse" | "resume" | "threadlocal"
                | "unreachable" | "dynclass" | "dynobj" | "dynrec" | "var"
                | "finally" | "noasync" | "assume"
```

### Labels

```{moonbit-grammar} moonbit-lexical
label ::= "_" { "A"..."Z" | "a"..."z" | "0"..."9" | "_" | `non-ascii` }+ "~"
        | (("a"..."z" | `non-ascii`) { "A"..."Z" | "a"..."z" | "0"..."9" | "_" | `non-ascii` } "~") except `keyword`"~"
```

The `~` must immediately follow the name. ASCII-uppercase identifiers and
keywords cannot form labels.

## Package Names

```{moonbit-grammar} moonbit-lexical
package-part ::= ("A"..."Z" | "a"..."z" | "_") { "A"..."Z" | "a"..."z" | "0"..."9" | "_" | "-" }

package-name ::= "@" `package-part` { "/" `package-part` }
```

Package names are ASCII-only. A hyphen cannot begin a package part. The leading
`@`, slashes, and parts must be adjacent.

## Attributes

```{moonbit-grammar} moonbit-lexical
attribute-name ::= ("A"..."Z" | "a"..."z" | "_") { "A"..."Z" | "a"..."z" | "0"..."9" | "_" }

attribute ::= "#" `attribute-name` [ "." `attribute-name` ] { `line-character` }
```

After the optional dot-qualified name, everything through the next newline is
the raw payload. Attributes are not permitted inside an `interpolation`. See
[Attribute](attributes.md) for the payload grammar.

## Numeric Literals

```{moonbit-grammar} moonbit-lexical
integer-nums ::= ("0"..."9") { "0"..."9" | "_" }
               | "0" ("x" | "X") ("0"..."9" | "A"..."F" | "a"..."f") { "0"..."9" | "A"..."F" | "a"..."f" | "_" }
               | "0" ("o" | "O") ("0"..."7") { "0"..."7" | "_" }
               | "0" ("b" | "B") ("0" | "1") { "0" | "1" | "_" }

integer-literal ::= `integer-nums` [ "UL" | "U" | "L" | "N" ]

double-dec ::= ("0"..."9") { "0"..."9" | "_" } "." { "0"..."9" | "_" }
               [ ("e" | "E") [ "+" | "-" ] ("0"..."9") { "0"..."9" | "_" } ]

double-hex ::= "0" ("x" | "X") ("0"..."9" | "A"..."F" | "a"..."f")
               { "0"..."9" | "A"..."F" | "a"..."f" | "_" } "."
               { "0"..."9" | "A"..."F" | "a"..."f" | "_" }
               [ ("p" | "P") [ "+" | "-" ] ("0"..."9") { "0"..."9" | "_" } ]

double-literal ::= `double-dec` | `double-hex`

float-dec ::= `double-dec` "F"

float-hex ::= "0" ("x" | "X") ("0"..."9" | "A"..."F" | "a"..."f")
              { "0"..."9" | "A"..."F" | "a"..."f" | "_" } "."
              { "0"..."9" | "A"..."F" | "a"..."f" | "_" }
              ("p" | "P") [ "+" | "-" ] ("0"..."9") { "0"..."9" | "_" } "F"

float-literal ::= `float-dec` | `float-hex`
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

```{moonbit-grammar} moonbit-lexical
tuple-accessor ::= "." { "0"..."9" }+

dot-identifier ::= "." ("A"..."Z" | "a"..."z" | "_" | `non-ascii`) { "A"..."Z" | "a"..."z" | "0"..."9" | "_" | `non-ascii` }
```

These forms contain no whitespace. Tuple accessors do not permit underscores,
and dot-identifiers use the identifier case rules without consulting the
keyword table, so `.if` is valid. A single `.` reports a lexical error.

## Operators and Delimiters

```{moonbit-grammar} moonbit-lexical
delimiter ::= "(" | ")" | "," | "::" | ":" | ";"
            | "[" | "]" | "{" | "}" | "[|" | "|]"

operator ::= "=>" | "->"
           | "&&" | "&" | "^"
           | "*" | "/" | "%"
           | "<<" | ">>"
           | "=" | ">" | "<|" | "<?" | "<+" | "<"
           | "==" | "!=" | "=~" | "<=" | ">="
           | "|" | "||" | "+" | "-" | "?" | "!"
           | "+=" | "-=" | "*=" | "/=" | "%=" | "|>"
           | ".." | "..=" | "..<" | "..<=" | ">.." | ">=.." | "..."
```

The longest listed token wins. MoonBit has no generic operator-name syntax.

## Automatic Semicolon Insertion

After a newline, the lexer may insert `;` when the preceding token can end a
statement and the following token can begin one. End of file is also an
eligible follower. It does not insert one before `}` or between adjacent
multiline string lines.

## `.mbti` Extensions

The `.mbti` lexical grammar adds this keyword to `.mbt`:

```{moonbit-grammar} moonbit-lexical
mbti-keyword ::= `keyword` | "package"
```

In `.mbti`, `package` takes precedence over identifiers and cannot form a
label. In `.mbt`, it follows the reserved-word behavior above and can
form `package~`.
