pub fn values() -> Array[Int] {
  label~: for ;; {
    let xs = [for _ in 0..<3 => { break label~ }]
    return xs
  }
  []
}
