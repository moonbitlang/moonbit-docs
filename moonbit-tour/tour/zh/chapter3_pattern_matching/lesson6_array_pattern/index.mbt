fn main {
  let array = [1, 2, 3, 4, 5, 6]
  let [a, b, ..] = array
  let [.., c, d] = array
  let [e,  ..,  f] = array
  println("a: \{a}, b: \{b}")
  println("c: \{c}, d: \{d}")
  println("e: \{e}, f: \{f}")
  println("sum of array: \{sum(array[:])}")
}

fn sum(array : ArrayView[Int]) -> Int {
  match array {
    [] => 0
    [x, .. as xs] => x + sum(xs)
  }
}
