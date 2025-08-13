fn greet(name~ : String = "World") -> Unit {
  println("Hello, " + name + "!")
}

fn main {
  // Can be called as:
  greet() // Uses default value "World"
  greet(name="Alice") // Uses provided value "Alice"
}