type A Int

fn A::f(self : A) -> Int {
  self._
}

fn main {
  let _ = f(A(1))
  // Warning:
  // This method is declared as A::f, calling this kind of method directly via
  // f(..) is deprecated, use qualified syntax A::f(..), or declare the method
  // as `fn f(self : A, ..)` instead.
}
