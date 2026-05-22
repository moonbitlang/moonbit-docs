# Borrow and Owned Attribute

The `#borrow` and `#owned` attributes are used on FFI declarations to describe
how reference-counted MoonBit arguments are passed to foreign code. This matters
for boxed MoonBit values such as `Bytes`, `String`, `FixedArray[T]`, and
abstract types, whose lifetimes are managed by reference counting on the C and
Wasm backends.

Use `#borrow(param)` when the foreign function only reads `param` during the
call and does not store or return it. A borrowed parameter remains owned by
MoonBit, so the foreign function does not need to call `moonbit_decref` or
`$moonbit.decref` for it.

Use `#owned(param)` when the foreign function takes ownership of `param`, for
example by storing it and releasing it later. An owned parameter must eventually
be released by the foreign side when it is no longer needed.

```{code-block} moonbit
:class: top-level
#borrow(filename)
extern "C" fn open(filename : Bytes, flags : Int) -> Int = "open"
```

For the full calling-convention rules, see
[FFI lifetime management](/language/ffi.md#the-borrow-and-owned-attribute).
