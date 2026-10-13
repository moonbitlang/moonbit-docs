///|
pub fn accumulate(acc~ : Int32, value : Int32) -> Int32 {
  acc + value
}

///|
test {
  let xs = [1, 2, 3, 4, 5]
  let sum = xs.fold(init=0, fn(acc, value) { accumulate(acc~, value) })
  inspect(sum, content="15")
}
