// start method 7
enum List[X] {
  Nil
  Cons(X, List[X])
}

fn List::concat[X](xs : List[List[X]]) -> List[X] {
  ...
}
// end method 7

// start method 3
fn map[X, Y](self : List[X], f : (X) -> Y) -> List[Y] {
  ...
}
// end method 3

// start method 6
fn f() -> Unit {
  let xs : @list.List[@list.List[Unit]] = Nil
  let _ = xs.concat()
  let _ = @list.List::concat(xs)
  let _ = @list.concat(xs)

}
// end method 6
