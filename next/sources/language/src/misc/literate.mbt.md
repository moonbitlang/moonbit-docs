<!-- start literate fences 1 -->
```mbt nocheck
///|
fn helper() -> Int32 {
  42
}
```

```mbt check
///|
test "forty two" {
  inspect(40 + 2, content="42")
}
```

```mbt nocheck
///|
fn native_only() -> Unit {
  ...
}
```
<!-- end literate fences 1 -->
