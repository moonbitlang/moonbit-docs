fn first_char(s : String) -> Result[Char, String] {
  if s.length() == 0 {
    Err("empty string")
  } else {
    Ok(s.char_at(0))
  }
}

fn main {
  let c1  = first_char("hello")
  let c2  = first_char("")
  println("\{c1.is_ok()}, \{c1}, \{c1.unwrap()}")
  println("\{c2.is_err()}, \{c2}")
}
