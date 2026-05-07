///|
fn use_named_pattern(a : A) -> Unit {
  match a {
    A(b=c) => println("Hello, world! \{c}")
  }
}
