func println(self : String) {
  self.print()
  '\n'.print()
}

func println(self : Char) {
  self.print()
  '\n'.print()
}

func init {
  match @lib.is_alpha('a') {
    true => "is alpha".println()
    false => "is not alpha".println()
  }
  match @lib.is_alpha('3') {
    true => "is alpha".println()
    false => "is not alpha".println()
  }
  match @lib.is_numeric('1') {
    true => "is numeric".println()
    false => "is not numeric".println()
  }
  match @lib.is_numeric('b') {
    true => "is numeric".println()
    false => "is not numeric".println()
  }
  match @lib.is_alphanumeric('a') {
    true => "is alphanumeric".println()
    false => "is not alphanumeric".println()
  }
  @lib.to_lower('H').println()
  @lib.to_upper('c').println()
  match @lib.is_whitespace(' ') {
    true => "True".println()
    false => "False".println()
  }
  match @lib.next('Z') {
    Some(v) => v.println()
    None => ()
  }
  match @lib.prev('A') {
    Some(v) => v.println()
    None => ()
  }
}

