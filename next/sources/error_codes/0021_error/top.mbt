enum E {
  A(Int, w~ : Int, h~ : Int)
}

fn main {
  match A(0, w=1, h=2) {
    A(v, w~) => { // Warning: The argument(s) h of constructor A are omitted.
      println(v)
      println(w)
    }
  }
}
