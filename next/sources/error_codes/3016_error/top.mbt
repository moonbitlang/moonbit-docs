///|
pub(all) enum A {
  A(b~ : Int)
}

///|
fn describe(a : A) -> Unit {
  match a {
    A(b~=c) => println("Hello, world! \{c}") // Error: unexpected `~` in argument. Did you mean `label=pattern` or `label~`?
  }
}

///|
test {
  describe(A(b=1))
}
