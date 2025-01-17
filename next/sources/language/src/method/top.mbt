// start method 1
pub(all) enum List[X] {
  Nil
  Cons(X, List[X])
}

pub fn concat[X](self : List[List[X]]) -> List[X] {
  ...
}
// end method 1

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
