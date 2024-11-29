enum List[T] {
  Nil
  Cons(T, List[T])
}

fn map[S, T](self : List[S], f : (S) -> T) -> List[T] {
  match self {
    Nil => Nil
    Cons(x, xs) => Cons(f(x), map(xs, f))
  }
}

fn reduce[S, T](self : List[S], op : (T, S) -> T, init : T) -> T {
  match self {
    Nil => init
    Cons(x, xs) => reduce(xs, op, op(init, x))
  }
}
