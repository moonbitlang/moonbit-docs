fn values() -> Iter[Int] {
  [| for i in 0..<3 => i |]
}

test {
  let mut sum = 0
  values().each(x => sum = sum + x)
  inspect(sum, content="3")
}
