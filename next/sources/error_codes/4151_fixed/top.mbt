pub fn callback() -> FuncRef[() -> Unit] {
  fn() {
    println(42)
  }
}
