typealias List[T] = @immut/list.T[T]
// start stream definition
enum Stream[T] {
  Empty
  Cons(T, () -> Stream[T])
}
// end stream definition

// start list conversion
fn[T] Stream::from_list(l : List[T]) -> Stream[T] {
  match l {
    Nil => Empty
    Cons(x, xs) => Cons(x, fn () { Stream::from_list(xs) })
  }
}
// end list conversion

// start map definition
fn[X, Y] map(self : Stream[X], f : (X) -> Y) -> Stream[Y] {
  match self {
    Empty => Empty
    Cons(x, xs) => Cons(f(x), fn () { xs().map(f) })
  }
}
// end map definition

// start take definition
fn[T] take(self : Stream[T], n : Int) -> List[T] {
  if n == 0 {
    Nil
  } else {
    match self {
      Empty => Nil
      Cons(x, xs) => Cons(x, xs().take(n - 1))
    }
  }
}
// end take definition