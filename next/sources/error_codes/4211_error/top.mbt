fn values() -> Iter[Int32] {
  let xs : Iter[Int32] = [| for _ in 0..<3 => { return Iter::empty() } |]
  xs
}
