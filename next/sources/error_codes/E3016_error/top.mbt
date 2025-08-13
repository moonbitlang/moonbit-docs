enum A {
  A(b~ : Int)
}

fn main {
  match A(b=1) {
    A(b~=c) => {
      println("Hello, world! \{c}") // Error: unexpected `~` in argument. Did you mean `label=pattern` or `label~`?
    }
  }
}