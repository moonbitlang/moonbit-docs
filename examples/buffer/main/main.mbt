fn main {
  let buf : @lib.SBuffer[Int] = @lib.SBuffer::new(5)
  println(buf.capacity()) // 5
  for index = 0; index < 8; index = index + 1 {
    buf.append(index)
  }
  println(buf.capacity()) // 10
  println(buf.length()) // 8
  buf.println() // [0,1,2,3,4,5,6,7]
  buf.clear()
  buf.println() // []
  println(buf.capacity()) // 10
  println(buf.length()) // 0
  buf.reset(10)
  println(buf.capacity()) // 10
  println(buf.length()) // 0
}

