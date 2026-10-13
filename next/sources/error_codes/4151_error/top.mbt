test {
  let x : Int32 = 42
  let _ : FuncRef[() -> Unit] = fn () { println(x) }
}