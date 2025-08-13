pub let a : Int = f() // Error: Definition cycle detected : a -> f -> a

fn f() -> Int { // Error: Definition cycle detected : a -> f -> a
  a
}