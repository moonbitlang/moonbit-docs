pub(open) trait I {
  f(Self) -> Unit
  g(Self) -> Unit
}

pub(all) struct P[X](X)

impl[X] I for P[X] with f(_self) {}
impl[X] I for P[X] with g(_self) {}

pub fn use_i(p : P[Int]) -> Unit {
  p.f()
  p.g()
}
