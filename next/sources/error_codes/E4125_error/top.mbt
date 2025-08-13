type A Double derive(Show)

pub fn A::check(self : A) -> Unit! {
  if self._.is_nan() {
    fail!("NaN")
  }
}

pub fn A::div(self : A, other : A) -> A {
  A(self._ / other._)
}

fn main {
  let a : A = 1.0
  let b : A = 2.0
  println(a.div(b)..check?())
}