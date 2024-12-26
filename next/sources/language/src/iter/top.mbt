// start iter 1
///|
fn filter_even(l : Array[Int]) -> Array[Int] {
  let l_iter : Iter[Int] = l.iter()
  l_iter.filter(fn { x => (x & 1) == 0 }).collect()
}

///|
fn fact(n : Int) -> Int {
  let start = 1
  let range : Iter[Int] = start.until(n)
  range.fold(Int::op_mul, init=start)
}
// end iter 1

// start iter 2
///|
fn iter(data : Bytes) -> Iter[Byte] {
  Iter::new(fn(visit : (Byte) -> IterResult) -> IterResult {
    for byte in data {
      guard let IterContinue = visit(byte) else { x => break x }

    } else {
      IterContinue
    }
  })
}
// end iter 2
