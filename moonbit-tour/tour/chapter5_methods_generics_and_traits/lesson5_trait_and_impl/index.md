# Traits

If methods define the behavior of a single type, a trait summarizes behavior shared by multiple types. When defining a new trait you usually write two parts:

- Trait definition: use the `trait` keyword; it lists the method signatures the trait contains.
- Trait implementation: use the `impl` keyword to provide the implementation for a concrete type.

In the example we define a trait `Equal` that provides an `is_equal` method: it takes two parameters of type `Self` (the concrete type implementing the trait) and returns a boolean indicating whether the two `Self` values are equal.

We implement `Equal` for the built‑in `Int` type and for a user‑defined `Pos` type, supplying concrete code for `is_equal`. Since the trait definition already declares the method’s types, parameter and return type annotations can be omitted inside the `impl`.

In `main`, calling `Equal::is_equal()` invokes the trait method; based on the types of `a` and `b`, different implementations are chosen:

- When `a` and `b` are `Int`, the code in `impl Int for Equal with is_equal` runs.
- When `a` and `b` are `Pos`, the code in `impl Pos for Equal with is_equal` runs.

The choice is resolved statically, there is no runtime dynamic dispatch overhead.

## Limitations

MoonBit follows the orphan rule: an `impl Type for Trait ...` must be in the same package as either the `Type` or the `Trait`; it cannot exist in isolation. This restriction guarantees uniqueness of trait implementations and prevents conflicts caused by duplicate impls in different packages or behavior changes due to external package modifications.

## Uses

In the standard library package `moonbitlang/core/builtin` there is a trait `Eq` that defines an `equal` method for comparing two values. The standard library already implements `Eq` for many built‑in types such as `Int`, `Bool`, and `Array`. It also provides the `Show` trait for converting values to their string form. Usage scenarios for these traits will be introduced later.

You may wonder why use a trait instead of defining separate `is_equal` methods on each type. The next section introduces an important purpose of traits: *trait bounds*.