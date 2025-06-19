// start doc string 1
/// Return a new array with reversed elements.
fn[T] reverse(xs : Array[T]) -> Array[T] {
  ...
}
// end doc string 1

// start todo 1
fn todo_in_func() -> Int {
  ...
}
// end todo 1

// start doc test 1
/// Increment an integer by one,
///
/// Example:
/// ```
/// inspect(incr(41), content="42")
/// ```
pub fn incr(x : Int) -> Int {
  x + 1
}
// end doc test 1

// start doc test 2
/// `c_incr(x)` is the same as the following C code:
/// ```c
/// x++
/// ```
pub fn c_incr(x : Ref[Int]) -> Int {
  let old = x.val
  x.val += 1
  old
}
// end doc test 2
