pub(open) trait I {
  f(Self) -> Unit
  g(Self) -> Unit
}

pub(all) struct P[X](X)

impl[X : Show] I for P[X] with f(_self) {}
impl[X] I for P[X] with g(_self) {}
