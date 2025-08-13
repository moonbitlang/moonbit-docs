fn main {
  let mut bytes = []
  loop {
    let bs = read()
    if bs == [] {
      break
    }
    bytes = [..bytes, ..bs]
  }
}
