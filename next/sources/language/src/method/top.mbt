// start method 1
pub(all) enum List[X] {
  Nil
  Cons(X, List[X])
}

pub fn[X] concat(self : List[List[X]]) -> List[X] {
  ...
}
// end method 1

pub fn[X, Y] List::map(self : List[X], f : (X) -> Y) -> List[Y] {
  match self {
    Nil => Nil
    Cons(x, xs) => Cons(f(x), xs.map(f))
  }
}

// start method overload example
struct T1 {
  x1 : Int
}

fn T1::default() -> T1 {
  { x1: 0 }
}

struct T2 {
  x2 : Int
}

fn T2::default() -> T2 {
  { x2: 0 }
}

test {
  let t1 = T1::default()
  let t2 = T2::default()

}
// end method overload example

// start method alias
// same as `fnalias List::map as map`
fnalias List::map

// list_concat is an alias of `List::concat`
fnalias List::concat as list_concat

// creating multiple alias in typename
fnalias List::(concat as c, map as m)
// end method alias