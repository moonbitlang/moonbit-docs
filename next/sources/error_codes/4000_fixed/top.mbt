///|
priv struct Container[T1, T2] {
  first : T1
  second : T2
}

///|
fn[A, B] transform(x : A, f : (A) -> B) -> B {
  f(x)
}

///|
test {
  let container : Container[Int, String] = { first: 1, second: "one" }
  inspect(container.first, content="1")
  inspect(container.second, content="one")
  inspect(transform(1, fn(x) { x.to_string() }), content="1")
}
