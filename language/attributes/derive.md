# Derive Attribute

Use `#derive(...)` before a type definition to generate implementations of
supported traits. Each field must satisfy the requirements of the derived
trait.

```moonbit
#derive(Debug)
struct DebugPoint {
  x : Int32
  y : Int32
}

pub extend DebugPoint with Debug::{to_repr}

test "derive debug struct" {
  let point = DebugPoint::{ x: 1, y: 2 }
  debug_inspect(point, content="{ x: 1, y: 2 }")
}
```

See [Deriving traits](https://docs.moonbitlang.com/en/latest/language/derive.html) for supported traits and their
options. `moon fmt` migrates the older trailing `derive(...)` syntax.
