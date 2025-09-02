///|
typealias @list.List

///|
/// start stream definition
enum Stream[T] {
  Empty
  Cons(T, () -> Stream[T])
}
// end stream definition

///|
/// start list conversion
fn[T] Stream::from_list(l : List[T]) -> Self[T] {
  match l {
    Empty => Empty
    More(x, tail=xs) => Cons(x, fn() { Stream::from_list(xs) })
  }
}
// end list conversion

///|
/// start map definition
fn[X, Y] map(self : Stream[X], f : (X) -> Y) -> Stream[Y] {
  match self {
    Empty => Empty
    Cons(x, xs) => Cons(f(x), fn() { xs().map(f) })
  }
}
// end map definition

///|
/// start take definition
fn[T] take(self : Stream[T], n : Int) -> List[T] {
  if n == 0 {
    @list.empty()
  } else {
    match self {
      Empty => @list.empty()
      Cons(x, xs) => xs().take(n - 1).add(x)
    }
  }
}
// end take definition
