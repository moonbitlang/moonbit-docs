pub fn f(name~ : String) -> Unit {
  println("Hello, \{name}")
}

fn main {
  f("John") // Error: The labels name~ are required by this function, but not supplied.
}