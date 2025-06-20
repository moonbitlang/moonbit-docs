fn main {
  let array = [1, 2, 3, 4, 5, 6]
  guard array is [a, b, ..]
  guard array is [.., c, d]
  guard array is [e,  ..,  f]
  println("a: \{a}, b: \{b}")
  println("c: \{c}, d: \{d}")
  println("e: \{e}, f: \{f}")
  println("sum of array: \{sum(array)}")
}

fn sum(array : @array.View[Int]) -> Int {
  match array {
    [] => 0
    [x, .. xs] => x + sum(xs)
  }
}
