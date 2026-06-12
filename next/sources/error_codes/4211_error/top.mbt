fn values() -> Iter[Int] {
  let xs : Iter[Int] = [ for _ in 0..<3 => { return Iter::empty() } ]
  xs
}
