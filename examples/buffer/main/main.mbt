func init {
  let buf : @lib.Buffer[Int] = @lib.Buffer::new(5)
  println(buf.capacity()) // 5
  var index = 0
  while index < 8 {
    buf.append(index)
    index = index + 1
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

