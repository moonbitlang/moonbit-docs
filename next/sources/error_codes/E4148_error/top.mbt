fn read() -> @bytes.View {
  ...
}

fn main {
  loop read() {
    [] => break
    _ => continue read~ read()
    //            ^~~~~
    // Error: The label read is undeclared.
  }
  // Defining the label here does not work since continue cannot jump to a different loop.
  read~: loop read() {
    [] => break
  }
}