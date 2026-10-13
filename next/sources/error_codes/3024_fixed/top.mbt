pub struct S {
  x : Int32
}

fn S::S(x : Int32) -> S {
  { x, }
}

pub fn make(x : Int32) -> S {
  S(x)
}
