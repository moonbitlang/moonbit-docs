///|
pub fn accumulate(acc~ : Int, value : Int) -> Int {
  acc + value
}

///|
test {
  let xs = [1, 2, 3, 4, 5]
  let sum = xs.fold(init=0, accumulate)
  //                       ^~~~~~~~~~~~
  // Error: Function with labelled arguments can only be applied directly.
}