# Error handling

The `!` syntax is used to singal a potential error raised from a function.

You can use `try { ... } catch { ... }` syntax to handle such occasion, or use
`?` syntax to convert the result to `Result`, a type representing the
computation result.
