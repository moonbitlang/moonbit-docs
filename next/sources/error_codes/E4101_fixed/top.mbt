type T Int

fn m(self: T, x: Int) -> Unit {
  println(self._ + x)
}

pub fn f(t: T, x: Int) -> Unit {
  fn(x: Int) { println(x)}(x)
  t.m(x)
}