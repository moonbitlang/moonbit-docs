///|
/// Generic, functional style linked list
enum MyList[T] {
  Cons(T, MyList[T])
  Nil
}

///|
/// Loop over `MyList`, running callback for each element
fn[T] MyList::each(self : Self[T], callback : (T) -> Unit) -> Unit {
  match self {
    Nil => ()
    Cons(elem, remains) => {
      callback(elem)
      remains.each(callback)
    }
  }
}

///|
fn main {
  // MyList with Int elements
  let ls1 : MyList[Int] = Cons(1, Cons(2, Cons(3, Nil)))
  ls1.each(println)

  // MyList with Bool elements
  let ls2 : MyList[Bool] = Cons(true, Cons(false, Nil))
  ls2.each(println)
}

