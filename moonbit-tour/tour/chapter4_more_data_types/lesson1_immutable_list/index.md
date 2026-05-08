# Immutable List

The immutable list resides in the package `@list`.

It is either:

- `Empty` : an empty list
- `More` : an element and the rest of the list.

You can construct `@list.List` using `@list.empty()` and `@list.cons(..)`. You can also use `xs.prepend(x)` to prepend an element to the front of the list.
