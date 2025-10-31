# Mutable fields in Struct

Struct fields are immutable by default, but we can make them mutable by using the `mut` keyword in the field declaration.

In previous lessons, we have learned that collections in MoonBit can be either mutable or immutable. This is achieved by using the `mut` keyword in their type declaration.

The `MutPoint` struct in the example has two fields, mutable `mx` and immutable `y`.
You can change the value of the `mx` field via reassignment but not the value of `y`.
