# Error handling

The `raise` syntax is used to signal a potential error raised from a function.

You can use `try { ... } catch { ... }` syntax to handle such occasion, or use
`try? ...` syntax to convert the result to `Result`, a type representing the
computation result.
