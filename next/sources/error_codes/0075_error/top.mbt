///|
fn length(view : ArrayView[Int]) -> Int {
  view.length()
}

///|
test {
  inspect(length([1, 2, 3][:]), content="3")
}
