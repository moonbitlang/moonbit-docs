// start iter 1
///|
fn filter_even(l : Array[Int]) -> Array[Int] {
  let l_iter : Iter[Int] = l.iter()
  l_iter.filter(x => (x & 1) == 0).collect()
}

///|
fn fact(n : Int) -> Int {
  let start = 1
  let range : Iter[Int] = start.until(n)
  range.fold(Int::mul, init=start)
}
// end iter 1

// start iter 2
///|
fn iter(data : Bytes) -> Iter[Byte] {
  let mut index = 0
  Iter::new(fn() -> Byte? {
    if index < data.length() {
      let byte = data[index]
      index += 1
      Some(byte)
    } else {
      None
    }
  })
}
// end iter 2
