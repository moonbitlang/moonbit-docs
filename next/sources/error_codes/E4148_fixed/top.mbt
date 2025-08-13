fn main {
  read~: loop read() {
    [] => break
    _ => continue read~ read()
  }
}