fn countdown(n : Int) -> Int {
  let mut count = n
  loop count {
    _..<0 => break
    _ => {
      continue count - 1
    }
  }
  return count
}
