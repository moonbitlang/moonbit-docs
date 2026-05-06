pub struct S {
  x : Int
  fn constr(x : Int) -> S
}

fn S::constr(x : Int) -> S {
  { x, }
}
