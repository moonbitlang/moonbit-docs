fn identity[T](value : T) -> T {
  //
  // Warning: The syntax fn f[..] for declaring polymorphic function is
  // deprecated. Use fn[..] f instead.
  value
}

fn main {
  println(identity("Hello, world!"))
}
