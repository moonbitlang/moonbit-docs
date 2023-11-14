fn init {
  match @lib.is_alpha('a') {
    true => println("is alpha")
    false => println("is not alpha")
  }
  match @lib.is_alpha('3') {
    true => println("is alpha")
    false => println("is not alpha")
  }
  match @lib.is_numeric('1') {
    true => println("is numeric")
    false => println("is not numeric")
  }
  match @lib.is_numeric('b') {
    true => println("is numeric")
    false => println("is not numeric")
  }
  match @lib.is_alphanumeric('a') {
    true => println("is alphanumeric")
    false => println("is not alphanumeric")
  }
  println(@lib.to_lower('H'))
  println(@lib.to_upper('c'))
  match @lib.is_whitespace(' ') {
    true => println("True")
    false => println("False")
  }
  match @lib.next('Z') {
    Some(v) => println(v)
    None => ()
  }
  match @lib.prev('A') {
    Some(v) => println(v)
    None => ()
  }
}

