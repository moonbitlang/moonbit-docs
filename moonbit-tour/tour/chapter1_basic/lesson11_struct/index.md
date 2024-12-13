# Struct

Structs are new types composed of other types. 

In the example we define a struct `Point` with two fields, `x` and `y`, both of which are integers. 

We can create an instance of `Point` by using the `{ x: 3, y: 4}`. The structs name can be omitted since the compiler can infer it from the labels `x` and `y`.

We can also add a `Point::` prefix to create an instance explicitly to disambiguate.

Anologous to tuples, we can access the fields of a struct using the syntax `point.x`.

The `derive(Show)` after the struct definition means that we can print the struct using the `println` function. 

The fields of a struct are immutable by default; they can't be changed after they are created. There is a syntax called *functional update* that allows you to create a new struct with some fields updated.

We will learn how to make the fields mutable in the next lesson.

