///|
pub fn f() -> Unit {
  for i = 0, radix = 10; i < 10; {
    println(i.to_string(radix~))
  }
}
