// eliminate pattern

///|
test {
  match Some(1) {
    Some(1) => ()
    Some(2..<_) => ()
    _ => ()
  }
}

// end eliminate pattern
