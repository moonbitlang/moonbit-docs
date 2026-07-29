# Struct

Struct is a new type composed of other types.

In the example we define a struct `Point` with two fields, `x` and `y`, both of which are integers.

We can create an instance of `Point` by writing `Point::{ x: 3, y: 4 }`.
Keeping the `Point::` prefix makes the constructed type explicit. The compiler
can infer an unqualified literal such as `{ x: 3, y: 4 }` in some contexts, but
the type-qualified form is preferred for a direct `let` binding.

Analogous to tuples, we can access the fields of a struct using the syntax `point.x`.

The `derive(Debug)` after the struct definition means that we can convert the struct to a debug representation, for example with `to_repr`.

The fields of a struct are immutable by default; they can't be changed after they are created. There is a syntax called *functional update* that allows you to create a new struct with some fields updated.

We will learn how to make the fields mutable in the next lesson.
