# Immutable List

The immutable list resides in the package `@immut/list`.

It is either:

- `Nil` : an empty list
- `Cons` : an element and the rest of the list.

As such, many operations such as reversing the list have complexity of O(n) and
may cause stack overflow.
