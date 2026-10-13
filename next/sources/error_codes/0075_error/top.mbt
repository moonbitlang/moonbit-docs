///|
fn length(view : ArrayView[Int32]) -> Int32 {
  view.length()
}

///|
test {
  inspect(length([1, 2, 3][:]), content="3")
}
