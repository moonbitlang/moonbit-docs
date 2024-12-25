fn first_char(s : String) -> Option[Char] {
  if s.length() == 0 {
    None
  } else {
    Some(s[0])
  }
}

fn main {
  let c1 : Char? = first_char("hello")
  let c2 : Option[Char] = first_char("")
  println("\{c1.is_empty()}, \{c1.unwrap()}")
  println("\{c2.is_empty()}, \{c2}")
}
