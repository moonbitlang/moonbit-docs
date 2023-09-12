func init {
  println(@lib.pi)
  println(@lib.max(4, 2)) // 4
  println(@lib.min(1.2, 1.21)) // 1.2
  println(@lib.int_max) // 2147483647
  println(@lib.int_min) // -2147483648
  // 214_748
  match @lib.parse_int("214748") {
    Some(v) => println(v)
    None => println("overflowed")
  }
  // overflowed
  match @lib.parse_int("2147483648") {
    Some(v) => println(v)
    None => println("overflowed")
  }
  // -2_147_483_648
  match @lib.parse_int("-2147483648") {
    Some(v) => println(v)
    None => println("overflowed")
  }
  // overflowed
  match @lib.parse_int("-2147483649") {
    Some(v) => println(v)
    None => println("overflowed")
  }
  // 291
  match @lib.parse_int("0x123") {
    Some(v) => println(v)
    None => println("overflowed")
  }
  // 117
  match @lib.parse_int("0b1110101") {
    Some(v) => println(v)
    None => println("overflowed")
  }
  // 83
  match @lib.parse_int("0o123") {
    Some(v) => println(v)
    None => println("overflowed")
  }
  println(@lib.abs_int(-3)) // 3
  // 720
  match @lib.factorial(6) {
    Some(v) => println(v)
    None => println("overflowed")
  }
}

