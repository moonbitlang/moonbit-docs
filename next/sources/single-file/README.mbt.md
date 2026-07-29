---
moonbit:
  import:
    - path: moonbitlang/core/ref
      alias: ref
  backend:
    native
---

```mbt check
fn answer() -> Int {
  let cell = @ref.Ref::{ val: 41 }
  cell.val + 1
}

///|
test "answer" {
  inspect(answer(), content="42")
}
```
