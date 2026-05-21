# Inline Attribute

The `#inline` attribute is an optimization hint for a function. It asks the
compiler to inline the function when possible:

```moonbit
#inline
fn add_one(x : Int) -> Int {
  x + 1
}
```

Use `#inline(never)` to ask the compiler not to inline a function:

```moonbit
#inline(never)
fn keep_stack_frame(x : Int) -> Int {
  x + 1
}
```

These attributes are hints. They do not change the source-level behavior of the
function.
