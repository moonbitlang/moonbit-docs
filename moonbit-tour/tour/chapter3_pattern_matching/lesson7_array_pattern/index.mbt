fn main {
  let array = [1, 2, 3, 4, 5, 6]
  match array {
    [a, b, ..] => println("a: \{a}, b: \{b}")
    _ => ()
  }
  match array {
    [.., c, d] => println("c: \{c}, d: \{d}")
    _ => ()
  }
  match array {
    [e,  ..,  f] => println("e: \{e}, f: \{f}")
    _ => ()
  }
  println("sum of array: \{sum(array)}")
}

fn sum(array : @array.View[Int]) -> Int {
  match array {
    [] => 0
    [x, .. xs] => x + sum(xs)
  }
}
