fn countdown(n : Int) -> Int {
  let mut count = n
  match count {
    _..<0 => ()
    _ => count = count - 1
  }
  return count
}
