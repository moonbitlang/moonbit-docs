type T Int

fn m(self: T, x: Int) -> Unit {
  println(self._ + x)
}

pub fn f(t: T, x: Int) -> Unit {
  x |> fn(x: Int) { println(x)}
//     ^^^^^^^^^^^^^^^^^^^^^^^^ Error: Unsupported expression after the pipe operator.
  x |> t.m()
//     ^^^^ Error: Unsupported expression after the pipe operator.
}