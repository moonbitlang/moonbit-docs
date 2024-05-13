pub fn assert_eq[T : Compare + Show](left : T, right : T) -> Unit {
  if left.compare(right) != 0 {
    abort(
      "assertion failed: (left == right)\n" + "left: " + left.to_string() + "\n" +
      "right: " + right.to_string() + "\n",
    )
  }
}

pub fn assert(x : Bool) -> Unit {
  if x != true {
    abort("assertion failed: " + x.to_string() + "\n")
  }
}

pub fn assert_ne[T : Compare + Show](left : T, right : T) -> Unit {
  if left.compare(right) == 0 {
    abort(
      "assertion failed: (left != right)\n" + "left: " + left.to_string() + "\n" +
      "right: " + right.to_string() + "\n",
    )
  }
}