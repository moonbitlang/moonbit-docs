pub struct S {
  x : Int
  fn new(x : Int) -> S
}

fn S::new(x : Int) -> S {
  { x, }
}

pub fn make(x : Int) -> S {
  S::new(x)
}
