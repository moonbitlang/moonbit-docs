///|
fn main {
  let mut sum = 0
  let input = [1, 2, 3]
  read~: loop input[:] {
    [] => break
    [head, .. tail] => {
      sum += head
      continue tail
    }
  }
  println(sum)
}
