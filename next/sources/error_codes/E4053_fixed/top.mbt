pub(all) type Wrap[T] T

fn f[T](self : Wrap[T]) -> Int {
  ignore(self)
  0
}

fn g(self : Wrap[(Int) -> Unit]) -> Unit {
  (self._)(0)
}

impl[X] A for Wrap[X] with f(self : Wrap[X]) -> Int {
  ignore(self)
  0
}