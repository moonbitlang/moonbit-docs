test {
  let mut a = 0
  a = 1
  println(a)
}

struct S {
  mut x : Int
//^^^
}

test {
  let s = { x: 1 }
  s.x = 2
}