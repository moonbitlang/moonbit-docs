# Option

`Option[Char]` represents a `Char` value that may or may not be present. It is a common way to handle exceptional cases. 

- `None` means the value is missing.
- `Some(e)` is a wrapper that contains the value `e`.

The `[Char]` part in the type is a type parameter, which means the value type in `Option` is `Char`. We can use `Option[String]`, `Option[Double]`, etc. We will cover generics later.

The type annotation `Option[A]` can be shortened to `A?`.

You can use `c1.is_empty()` to check if the value is missing and `c1.unwrap()` to get the value.

