pub let x: Int = { return 42 }
//                 ^^^^^^^^^ Error: Return must be inside a function.
pub let y: Int = {
  if x == 42 {
    x + 1
  } else {
    return 0
//  ^^^^^^^^ Error: Return must be inside a function.
  }
}