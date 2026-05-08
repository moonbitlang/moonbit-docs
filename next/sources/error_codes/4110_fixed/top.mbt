///|
pub fn stop_at_zero(x : Int) -> Unit {
  for i in 0..<=x {
    if i == 0 {
      break
    }
    println(i)
  }
}
