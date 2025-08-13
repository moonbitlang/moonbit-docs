pub fn f(x: Int) -> Unit {
   for i = 0, i = 1; i < x; i = i + 1 {
//            ^ --- Error: i is declared multiple times in this for-loop
    println(i)
  }
}