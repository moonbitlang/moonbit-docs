pub struct S {
  x : Int
}

fn S::S(x : Int) -> S {
  { x, }
}

pub fn make(x : Int) -> S {
  S(x)
}
