pub fn f1() -> Unit {
  fn f(x) {
//     ^ Warning: The type of this expression is Option[_/0], which contains
//                unresolved type variables. The type variable is default to
//                Unit.
    match x {
      None => ()
      Some(a) => println(a)
    }
  }

  f(None)
}

pub fn f2() -> Unit {
  fn f(x : Array[_]) -> Int {
//     ^ Warning: The type of this expression is Array[_/0], which contains
//                unresolved type variables. The type variable is default to
//                Unit.
    x.length()
  }

  println(f([]))
}

fn main {
  let a = []
//        ^^ Warning: The type of this expression is Array[_/0], which contains
//           unresolved type variables. The type variable is default to Unit.
  println(a.length())
  let b = None
//        ^^ Warning: The type of this expression is Option[_/0], which contains
//           unresolved type variables. The type variable is default to Unit.
  println(b.is_empty())
}

