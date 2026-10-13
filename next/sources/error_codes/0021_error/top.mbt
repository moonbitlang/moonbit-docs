enum E {
  A(Int32, w~ : Int32, h~ : Int32)
}

fn main {
  match A(0, w=1, h=2) {
    A(v, w~) => { // Warning: The argument(s) h of constructor A are omitted.
      println(v)
      println(w)
    }
  }
}
