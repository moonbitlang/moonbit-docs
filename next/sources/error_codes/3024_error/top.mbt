pub struct S {
  x : Int32
  fn constr(x : Int32) -> S
}

fn S::constr(x : Int32) -> S {
  { x, }
}
