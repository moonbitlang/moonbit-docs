```moonbit
struct Foo[T] {
  bar : Int
}

fn init {
  let foo : Foo[Int] = { bar : 42 }
  let baz = { bar : 42 }
  let _ = foo.bar
  let _ = baz.bar
}
```