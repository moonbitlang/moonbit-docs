pub const Value : Int = 1

fn main {
  match { ... } {
    Value(_) => println("Value")
  //^~~~~
  // Error: 'Value' is a constant, not a constructor, it cannot be applied to arguments.
  }
}