///|
pub fn f() -> Unit {
  let radix = 10
  for i = 0; i < 10; i = i + 1 {
    println(i.to_string(radix~))
  }
}
