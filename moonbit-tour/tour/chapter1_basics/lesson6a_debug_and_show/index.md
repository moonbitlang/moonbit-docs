# Printing Values

You have already used `println` and string interpolation to print simple values.

In string interpolation, the expression inside `\{...}` is converted to a string
using its output format, then inserted into the surrounding string. This is
useful when the value has a clear display format.

But data structures are often different. Some of them do not have a display
format and cannot be used directly in interpolation. When you want to inspect an
array or another structured value, use `to_repr`:

```mbt
println("emails: \{to_repr(emails)}")
```

`to_repr` produces a `Repr`: a structured, human-readable representation of the
value. It is meant for inspection, not for a custom display format such as JSON,
XML, or HTML. For example, an array of strings is printed over multiple lines,
and each string is printed with double quotes.

`debug(x)` is a shorthand for `println("\{to_repr(x)}")`.

## Show And Debug

The output format used by interpolation is provided by the `Show` trait. A type
should provide `Show` when it has a chosen display format, such as plain text,
XML, JSON, HTML, or another format. The structured inspection format produced by
`to_repr` and `debug` is provided by the `Debug` trait. We will cover traits in
a later chapter.
