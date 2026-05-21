# `as_free_fn` Attribute

The `#as_free_fn` attribute is used to mark a method that it is declared as a free function as well.
It can also change the visibility of the free function, the name of the free function, and provide separate deprecation warning.

```moonbit
#as_free_fn(dec, visibility="pub", deprecated="use `Int::decrement` instead")
#as_free_fn(visibility="pub")
fn Int::decrement(i : Self) -> Self {
  i - 1
}

test {
  let _ = decrement(10)
  let _ = (10).decrement()
}
```
