///|
pub(all) enum A {
  A(b~ : Int)
}

///|
fn use_pun_pattern(a : A) -> Unit {
  match a {
    A(b~) => println("Hello, world! \{b}")
  }
}

///|
test {
  use_pun_pattern(A(b=1))
  use_named_pattern(A(b=1))
}
