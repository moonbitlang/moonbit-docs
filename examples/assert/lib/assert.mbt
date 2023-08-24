pub func assert_eq[T : Compare + Show](left : T, right : T) {
  if left.compare(right) != 0 {
    abort("assertion failed: (left == right)\n" + "left: " + left.to_string() + "\n" + "right: " + right.to_string() + "\n")
  }
}

pub func assert(x : Bool) {
  if x != true {
    abort("assertion failed: " + x.to_string() + "\n")
  }
}

pub func assert_ne[T : Compare + Show](left : T, right : T) {
  if left.compare(right) == 0 {
    abort("assertion failed: (left != right)\n" + "left: " + left.to_string() + "\n" + "right: " + right.to_string() + "\n")
  }
}

func init {
  ()
}

