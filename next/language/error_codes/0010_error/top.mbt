///|
test {
  match Some(1) {
    Some(1) | Some(1) => ()
    Some(2..<_) | Some(2) => ()
    _ | None => ()
  }
}
