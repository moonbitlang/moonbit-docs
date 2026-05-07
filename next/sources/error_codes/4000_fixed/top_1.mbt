///|
priv struct Box[T] {
  value : T
}

///|
fn[A] identity(x : A) -> A {
  x
}

///|
test {
  let container : Box[Int] = { value: 1 }
  inspect(container.value, content="1")
  inspect(identity("value"), content="value")
}
