pub fn greet(name : String = "World") -> Unit {
  //                       ^ Error: Only labelled arguments can have default value.
  println("Hello, " + name + "!")
}
