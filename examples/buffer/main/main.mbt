func println(self : Int) {
  self.print()
  '\n'.print()
}

func init {
  let buf : @lib.Buffer[Int] = @lib.Buffer::new(5)
  buf.capacity().println() // 5
  var index = 0
  while index < 8 {
    buf.append(index)
    index = index + 1
  }
  buf.capacity().println() // 10
  buf.length().println() // 8
  var index = 0
  buf.println() // [0,1,2,3,4,5,6,7]
  buf.clear()
  buf.println() // []
  buf.capacity().println() // 10
  buf.length().println() // 0
  buf.reset(10)
  buf.capacity().println() // 10
  buf.length().println() // 0
}

