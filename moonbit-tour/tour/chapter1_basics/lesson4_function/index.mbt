///|
fn add(a : Int, b : Int) -> Int {
  return a + b
}

///|
fn multiply(x : Int, y : Int) -> Int {
  x * y
}

///|
fn print_position(x~ : Int, y~ : Int) -> Unit {
  println("(\{x},\{y})")
}

///|
fn print_greeting(name? : String = "guest") -> Unit {
  println("Hello, " + name + "!")
}

///|
fn main {
  println(add(1, 2))
  println(multiply(2, 2))
  print_position(x=10, y=20)
  print_position(y=20, x=10)
  print_greeting()
  print_greeting(name="alice")
}
