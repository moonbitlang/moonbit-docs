// start method declaration example
enum List[X] {
  Nil
  Cons(X, List[X])
}

fn[X] List::length(xs : List[X]) -> Int {
  ...
}
// end method declaration example

fn _call_syntax_example() -> Unit {
  // start method call syntax example
  let l : List[Int] = Nil
  println(l.length())
  println(List::length(l))
  // end method call syntax example
}

fn f() -> Unit {
  let xs : @list.List[@list.List[Unit]] = Nil
  // start dot syntax example
  // assume `xs` is a list of lists, all the following two lines are equivalent
  let _ = xs.concat()
  let _ = @list.List::concat(xs)
  // end dot syntax example
}
