///|
test {
  // start example
  match A(0, w=1, h=2) {
    A(v, w~, h~) => {
      println(v)
      println(w)
      println(h)
    }
  }
}
