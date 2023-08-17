pub func undefined[A, B](x : A) -> B {
  undefined(())
}

pub func id[A](x : A) -> A {
  x
}

pub func const[A, B](x : A) -> (B) -> A {
  fn(y) { x }
}

pub func compose[A, B, C](f : (B) -> C, g : (A) -> B) -> (A) -> C {
  fn(x) { f(g(x)) }
}

pub func println[T : Show](x : T) {
  "\(x)\n".print()
}

struct Cont[R, A] {
  runCont_ : ((A) -> R) -> R
}

pub func runCont[R, A](self : Cont[R, A], k : (A) -> R) -> R {
  match self {
    {runCont_: f} => f(k)
  }
}

pub func cont[R, A](f : ((A) -> R) -> R) -> Cont[R, A] {
  { runCont_: f }
}

pub func fmap[R, A, B](f : (A) -> B, self : Cont[R, A]) -> Cont[R, B] {
  cont(fn(k) { self.runCont(compose(k, f)) })
}

pub func return_[R, A](x : A) -> Cont[R, A] {
  cont(fn(k) { k(x) })
}

pub func bind[R, A, B](self : Cont[R, A], f : (A) -> Cont[R, B]) -> Cont[R, B] {
  cont(fn(k) { self.runCont(fn(x) { f(x).runCont(k) }) })
}

pub func withCont[R, A, B](self : Cont[R, B], f : ((A) -> R) -> (B) -> R) ->
     Cont[R, A] {
  cont(fn(y) { self.runCont(f(y)) })
}

pub func mapCont[R, A, B](self : Cont[R, A], f : (R) -> R) -> Cont[R, A] {
  cont(fn(k) { f(self.runCont(k)) })
}

pub func callCC[R, A, B](f : ((A) -> Cont[R, B]) -> Cont[R, A]) -> Cont[R, A] {
  cont(fn(k) { f(fn(x) { cont(fn(y) { k(x) }) }).runCont(k) })
}

pub func lift[R, A, B](self : Cont[R, A]) -> Cont[Cont[R, B], A] {
  cont(fn(k) { self.bind(k) })
}

pub func reset[R, R0](x : Cont[R, R]) -> Cont[R0, R] {
  return_(x.runCont(id))
}

pub func shift[R, S, A](f : ((A) -> Cont[S, R]) -> Cont[R, R]) -> Cont[R, A] {
  cont(fn(k) { f(compose(return_, k)).runCont(id) })
}

