func println(self : Float) {
  self.print()
  '\n'.print()
}

func println(self : Int) {
  self.print()
  '\n'.print()
}

func println(self : String) {
  self.print()
  '\n'.print()
}

func init {
  @lib.pi.println()
  @lib.max(4, 2).println() // 4
  @lib.min(1.2, 1.21).println() // 1.2
  @lib.int_max.println() // 2147483647
  @lib.int_min.println() // -2147483648
  // 214_748
  match @lib.parse_int("214748") {
    Some(v) => v.println()
    None => "overflowed".println()
  }
  // overflowed
  match @lib.parse_int("2147483648") {
    Some(v) => v.println()
    None => "overflowed".println()
  }
  // -2_147_483_648
  match @lib.parse_int("-2147483648") {
    Some(v) => v.println()
    None => "overflowed".println()
  }
  // overflowed
  match @lib.parse_int("-2147483649") {
    Some(v) => v.println()
    None => "overflowed".println()
  }
  // 291
  match @lib.parse_int("0x123") {
    Some(v) => v.println()
    None => "overflowed".println()
  }
  // 117
  match @lib.parse_int("0b1110101") {
    Some(v) => v.println()
    None => "overflowed".println()
  }
  // 83
  match @lib.parse_int("0o123") {
    Some(v) => v.println()
    None => "overflowed".println()
  }
  @lib.abs_int(-3).println() // 3
  // 720
  match @lib.factorial(6) {
    Some(v) => v.println()
    None => "overflowed".println()
  }
}

