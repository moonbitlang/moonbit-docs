# Special Syntax

## Pipelines

MoonBit provides convenient pipe syntaxes `x |> f(y)` and `f <| x`, which can be used to chain regular function calls or make nested builder-style code easier to read:

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:dedent:
:start-after: start operator 4
:end-before: end operator 4
```

The MoonBit code follows the *data-first* style, meaning the function places its "subject" as the first argument.
Thus, the pipe operator inserts the left-hand side value into the first argument of the right-hand side function call by default.
For example, `x |> f(y)` is equivalent to `f(x, y)`.

You can use the `_` operator to insert `x` into any argument of the function `f`, such as `x |> f(y, _)`, which is equivalent to `f(y, x)`. Labeled arguments are also supported.

The pipe operator can also connect to an arrow function. When piping into an arrow function, the function body must be wrapped in curly braces, for example `value |> x => { x + 1 }`.

The reverse pipe operator applies the right-hand side as the final argument of the left-hand side call. For example, `f <| x` is equivalent to `f(x)`, and `f(a, b) <| c` is equivalent to `f(a, b, c)`. This is especially useful for DSL-like code, since nested calls such as `div([text("hello")])` can instead be written as `div <| [text <| "hello"]`.

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:dedent:
:start-after: start operator 4 reverse
:end-before: end operator 4 reverse
```

Because reverse pipe attaches the final argument, it also works well with functions whose last argument is a lambda, enabling a trailing-lambda style such as `section("toolbar") <| fn () { ... }`.


## Cascade Operator

The cascade operator `..` is used to perform a series of mutable operations on
the same value consecutively. The syntax is as follows:

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:dedent:
:start-after: start operator 5
:end-before: end operator 5
```

Here, `x..f()` is equivalent to `{ x.f(); x }`.


Consider the following scenario: for a `StringBuilder` type that has methods
like `write_string`, `write_char`, `write_object`, etc., we often need to perform
a series of operations on the same `StringBuilder` value:

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:dedent:
:start-after: start operator 6
:end-before: end operator 6
```

To avoid repetitive typing of `builder`, its methods are often designed to
return `self` itself, allowing operations to be chained using the `.` operator.
To distinguish between immutable and mutable operations, in MoonBit,
for all methods that return `Unit`, cascade operator can be used for
consecutive operations without the need to modify the return type of the methods.

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:dedent:
:start-after: start operator 7
:end-before: end operator 7
```

## is Expression

The `is` expression tests whether a value conforms to a specific pattern. It
returns a `Bool` value and can be used anywhere a boolean value is expected,
for example:

```{literalinclude} /sources/language/src/is/top.mbt
:language: moonbit
:dedent:
:start-after: start is 1
:end-before: end is 1
```

Pattern binders introduced by `is` expressions can be used in the following
contexts:

1. In boolean AND expressions (`&&`):
   binders introduced in the left-hand expression can be used in the right-hand
   expression

   ```{literalinclude} /sources/language/src/is/top.mbt
   :language: moonbit
   :dedent:
   :start-after: start is 2
   :end-before: end is 2
   ```

2. In the first branch of `if` expression: if the condition is a sequence of
   boolean expressions `e1 && e2 && ...`, the binders introduced by the `is`
   expression can be used in the branch where the condition evaluates to `true`.

   ```{literalinclude} /sources/language/src/is/top.mbt
   :language: moonbit
   :dedent:
   :start-after: start is 3
   :end-before: end is 3
   ```

3. In the following statements of a `guard` condition:

   ```{literalinclude} /sources/language/src/is/top.mbt
   :language: moonbit
   :dedent:
   :start-after: start is 4
   :end-before: end is 4
   ```

4. In the body of a `while` loop:

   ```{literalinclude} /sources/language/src/is/top.mbt
   :language: moonbit
   :dedent:
   :start-after: start is 5
   :end-before: end is 5
   ```

Note that `is` expression can only take a simple pattern. If you need to use
`as` to bind the pattern to a variable, you have to add parentheses. For
example:
```{literalinclude} /sources/language/src/is/top.mbt
:language: moonbit
:dedent:
:start-after: start is 6
:end-before: end is 6
```

## Regex Literal Expression

`re"..."` is a regex literal expression. Its type is `Regex`.

Regex literals are ordinary expressions, so they can be stored in local
bindings, passed as arguments, used as default argument values, and defined as
constants:

```moonbit
let r : Regex = re"a(b+)"
const IDENT_START : Regex = re"[A-Za-z_]"
const IDENT : Regex = IDENT_START + re"[A-Za-z0-9_]*"
```

Regex values can also be combined with `+` for sequence and `|` for
alternation. In places that require a regex constant expression, such as
[`=~`](#regex-match-expression), named `const` values defined from regex
literals can be referenced directly.

Unlike ordinary string literals, regex literals do not require double-escaping
backslashes. For example, write `re"/\*"` instead of `re"/\\*"`.

```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:dedent:
:start-after: start regex literal 1
:end-before: end regex literal 1
```

Invalid regex literals are rejected at compile time.

Regex literals use MoonBit's regex syntax. The supported forms include:

- Literal characters: ordinary characters match themselves
- Wildcard: `.` matches any single character, including newline
- Character classes: `[abc]`, `[^abc]`, `[a-z]`
- POSIX classes inside character classes: `[[:digit:]]`, `[[:alpha:]]`,
  `[[:space:]]`, `[[:word:]]`, `[[:xdigit:]]`, etc.
- Quantifiers: `*`, `+`, `?`, `{n}`, `{n,}`, `{n,m}`
- Non-greedy quantifiers: `*?`, `+?`, `??`, `{n}?`, `{n,}?`, `{n,m}?`
- Grouping and alternation: `( ... )`, `(?: ... )`, `(?<name> ... )`, `a|b`
- Assertions: `^`, `$`, `\b`, `\B`
- Scoped modifier: `(?i: ... )` for case-insensitive matching

Escape handling is regex-oriented rather than string-oriented. Common escapes
include `\n`, `\r`, `\t`, `\f`, `\v`, escaped metacharacters such as `\.` and
`\(`, and Unicode escapes `\uXXXX` / `\u{X...}`. To match a literal `{`, use
`[{]` rather than `\{`. This leaves room for future interpolation support in
regex literals, where `\{` would conflict with the interpolation syntax.

There are several important semantics and restrictions:

- `^` and `$` are non-multiline anchors: they match only the beginning and end
  of the whole input
- `\b` and `\B` are currently usable when a regex literal is handled as a
  first-class `Regex` value
  They are not currently available in `regex match expression` constant
  contexts such as [`=~`](#regex-match-expression), but this restriction is
  expected to be relaxed in the future
- POSIX character classes are ASCII-based
- `\d`, `\D`, `\s`, `\S`, `\w`, and `\W` are not supported
  Use `[[:digit:]]`, `[^[:digit:]]`, `[[:space:]]`, `[^[:space:]]`,
  `[[:word:]]`, and `[^[:word:]]` instead
- `\xHH` byte escapes are not supported in `re"..."`; use Unicode escapes or
  ordinary characters instead
- Lookahead, lookbehind, backreferences, and character-class set operations are
  not supported
- In character classes, `-` is used for ranges
  To match a literal dash, escape it as `\-`; putting `-` at the start or end
  of a character class is not supported

Named capture groups such as `(?<id>[0-9]+)` belong to the `Regex` value
itself. They are useful with APIs such as `Regex::execute` and
`MatchResult::named_group`, but they do not introduce MoonBit binders by
themselves.

When a regex literal is used as a first-class `Regex` value, operations such
as `Regex::execute` use first-match semantics: they return the first match
found from the search position. They do not provide a longest-match mode.

## Regex Match Expression

Regex match expressions use the `=~` operator to search a `StringView` with a 
regex constant expression. This is a newer regex-matching form intended to 
replace experimental `lexmatch`. The expression returns `Bool`.

```moonbit
input =~ re"abc"
input =~ ((PREFIX + SUFFIX) as whole, before=head, after=tail)
input =~ (re"b", before~, after~)
```

The right-hand side must be a regex constant expression: a regex literal such
as `re"abc"`, a named `const`, or an expression built from constants with `+`
(concatenation), `|` (alternation), and parentheses. Arbitrary runtime values
are not allowed.

Use `as` to bind the matched substring. Use `before` and `after` to bind the
unmatched prefix and suffix as `StringView`; `before~` and `after~` are
shorthand forms that bind variables named `before` and `after`.

This is separate from regex named capture groups. For example, in
`re"(?<id>[0-9]+)"`, the name `id` is part of the regex engine's capture
metadata, not a MoonBit binder. If you need a binder in `=~`, use `as`, such
as `(re"(?<id>[0-9]+)" as digits)`.

Like `is`, binders introduced by `=~` can be used in the same boolean-flow
contexts, such as the right-hand side of `&&` and the true branch of `if`.
Regex matching is search-based by default, so `"zabc!" =~ re"abc"` is `true`.
Use anchors such as `^` and `$` when you need to constrain the match to the
beginning or end of the input.

`=~` also uses first-match semantics. It will not support longest-match
behavior.

```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:dedent:
:start-after: start regex match 1
:end-before: end regex match 1
```

In the example above, `head`, `ident`, `tail`, `before`, `after`, and `rest`
have type `StringView`. The binder `ch` has type `Char`, because `re"."`
matches exactly one character.

## Lexmatch

```{warning}
`lexmatch` and `lexmatch?` are deprecated. Prefer
[regex match expression](#regex-match-expression) in new code.
This section is kept as reference for existing code.
```

`lexmatch` matches a `String` against a regex pattern and lets you bind the
pieces of a match. The search-mode pattern is `(before, regex pieces, after)`,
where `before` and `after` are optional bindings for the unmatched prefix and
suffix, separated by commas. The regex pieces in the middle are separated by
whitespace only. The regex itself is written as a sequence of string literals,
so you can split it across lines or insert comments between parts. You can
also bind a matched sub-pattern using `as`, such as `("b*" as b)`.

`lexmatch?` is a boolean check similar to `is`, and it can introduce binders
for use in the same contexts as `is` expressions.

In old code, search-mode `lexmatch` looked like this:

```moonbit
lexmatch text {
  (before, "a" ("b*" as b) "c", after) => ...
  _ => ...
}

if text lexmatch? ("a" ("b*" as b) "c") && b.length() > 0 {
  ...
}
```

In new code, write those search-mode checks with `=~` instead.

`lexmatch` also supports a lexer-style mode: `lexmatch <expr> with longest`,
which picks the longest match among alternatives (for example, `if|[a-z]*`
matches `iff` as `iff` in longest mode, while first-match search mode matches
`if` first). Regex match expressions do not provide this longest-match mode.

Regex literals support `\b` and `\B` as part of the regex syntax, but these
word-boundary assertions are not currently available in `regex match
expression` constant contexts. They do work when the regex is used as a
first-class `Regex` value, and this restriction is expected to be relaxed in
the future. Regex literals also do not support `\d`, `\D`, `\s`, `\S`, `\w`,
or `\W`. Use POSIX character classes like `[[:digit:]]` inside character
classes instead.

```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:dedent:
:start-after: start lexmatch 1
:end-before: end lexmatch 1
```

## Spread Operator

MoonBit provides a spread operator to expand a sequence of elements when
constructing `Array`, `String`, and `Bytes` using the array literal syntax. To
expand such a sequence, it needs to be prefixed with `..`, and it must have
`iter()` method that yields the corresponding type of element.

For example, we can use the spread operator to construct an array:

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:dedent:
:start-after: start spread 1
:end-before: end spread 1
```

Similarly, we can use the spread operator to construct a string:

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:dedent:
:start-after: start spread 2
:end-before: end spread 2
```

The last example shows how the spread operator can be used to construct a bytes
sequence.

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:dedent:
:start-after: start spread 3
:end-before: end spread 3
```


## TODO syntax

The `todo` syntax (`...`) is a special construct used to mark sections of code that are not yet implemented or are placeholders for future functionality. For example:

```{literalinclude} /sources/language/src/misc/top.mbt
:language: moonbit
:start-after: start todo 1
:end-before: end todo 1
```
