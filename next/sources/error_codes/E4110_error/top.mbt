pub fn f(x: Int) -> Unit {
  for i in 0..=x {
    break i
//  ^^^^^^^^ Error: The for loop is not expected to yield a value, please
//                  remove the argument of the `break` or add an `else` branch.
  }
}