enum A {
  A(b~ : Int)
}

fn main {
  match A(b=1) {
    A(b~) => {
      println("Hello, world! \{b}")
    }
  }
}