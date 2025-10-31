# Trait Bounds

Previously we introduced how to write a generic function `swap`:

```moonbit
fn[T] swap(arr : Array[T]) -> Unit {
  let tmp : T = arr[0]
  arr[0] = arr[1]
  arr[1] = tmp
}
```

The `swap` function only reorders elements in the array; it cannot perform any operation on the elements themselves. This is because `T` is completely unknown inside `swap`: we do not know which methods `T` supports, such as comparing two elements for equality or printing a value for debugging.

We can attach trait bounds to `T` using a type‑like annotation. The syntax `T : Eq` means that `T` must implement the `Eq` trait. A generic parameter can have multiple bounds, for example `T : Eq + Show` means `T` must implement both `Eq` and `Show`. This guarantees that we can safely call the methods of those traits in the function body.

The example changes the behavior of `swap`: before swapping the elements it prints debug information. The `Show` trait provides a `to_string` method, so we can call `to_string` on values of type `T` to convert them to strings, or use them directly in string interpolation.

The example also includes a `find_index` function that tries to locate an element in an array. If found, it returns the index; otherwise it returns `None`. To compare array elements with the target element, we add the `Eq` trait bound to the generic parameter `T`, allowing us to call `Eq::equal` for the comparison.

