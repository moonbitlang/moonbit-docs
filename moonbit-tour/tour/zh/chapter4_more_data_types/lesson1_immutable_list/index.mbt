fn count[A](list : @immut/list.T[A]) -> UInt {
  match list {
    Nil => 0
    Cons(_, rest) => count(rest) + 1 // may overflow
  }
}

///|
fn main {
  let empty_list : @immut/list.T[Int] = Nil
  let list_1 = @immut/list.Cons(1, empty_list)
  let list_2 = @immut/list.Cons(2, list_1)
  let list_3 = @immut/list.Cons(3, empty_list)
  let reversed_1 = list_1.rev()
  let n = count(reversed_1)
}
