pub fn f(xs: Array[Int]) -> Int {
  for i in xs {
    ignore(i)
  } else {
    break 42
//  ^^^^^^^^ Error: 'break' outside of a loop
  }
}

pub fn g(x: Int) -> Int {
  continue x
// ^^^^^^^^ Error: 'continue' outside of a loop
}

fn main {
  let x = { break }
//          ^^^^^ Error: 'break' outside of a loop
  println(x)
}