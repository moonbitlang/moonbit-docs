enum A {
  A(b~ : Int)
}

fn main {
  match A(b=1) {
    A(b=c) => {
      println("Hello, world! \{c}")
    }
  }
}