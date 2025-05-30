enum List[T] {
  Nil
  Cons(T, List[T])
}

fn[S, T] map(self : List[S], f : (S) -> T) -> List[T] {
  match self {
    Nil => Nil
    Cons(x, xs) => Cons(f(x), xs.map(f))
  }
}

fn[S, T] reduce(self : List[S], op : (T, S) -> T, init : T) -> T {
  match self {
    Nil => init
    Cons(x, xs) => xs.reduce(op, op(init, x))
  }
}
