fn main {
  // create Tuple 
  let tuple = (3.14, false, [1,2,3])  
  let tuple2 : (Float, Bool, Int) = (2.1, true, 20)
  println(tuple)

  // Accessing tuple elements
  println(tuple.0)
  println(tuple.2)

  // Tuple can also be destructured. 
  let (a, b, c) = f()
  println("\{a}, \{b}, \{c}")
}

fn f() -> (Int, Bool, Double) {
  (1, false, 3.14) // return multiple values via tuple
}
