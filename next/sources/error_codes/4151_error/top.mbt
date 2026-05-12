test {
  let x : Int = 42
  let _ : FuncRef[() -> Unit] = fn () { println(x) }
}