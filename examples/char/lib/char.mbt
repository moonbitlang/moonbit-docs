pub fn is_valid(c : Char) -> Bool {
  c.to_int() >= 0 &&
  (c.to_int() <= 0xD7FF || c.to_int() >= 0xE000) && c.to_int() <= 0x10FFFF
}

pub fn is_alpha(c : Char) -> Bool {
  c.compare('a') >= 0 && c.compare('z') <= 0 ||
  c.compare('A') >= 0 && c.compare('Z') <= 0
}

pub fn is_numeric(c : Char) -> Bool {
  c.compare('0') >= 0 && c.compare('9') <= 0
}

pub fn is_alphanumeric(c : Char) -> Bool {
  is_alpha(c) || is_numeric(c)
}

pub fn to_lower(c : Char) -> Char {
  if c.compare('A') >= 0 && c.compare('Z') <= 0 {
    return Char::from_int(c.to_int() - 'A'.to_int() + 'a'.to_int())
  }
  return c
}

pub fn to_upper(c : Char) -> Char {
  if c.compare('a') >= 0 && c.compare('z') <= 0 {
    return Char::from_int(c.to_int() - 'a'.to_int() + 'A'.to_int())
  }
  return c
}

pub fn is_whitespace(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r'
}

pub fn next(c : Char) -> Option[Char] {
  let ne = Char::from_int(c.to_int() + 1)
  if is_valid(ne) {
    return Some(ne)
  }
  None
}

pub fn prev(c : Char) -> Option[Char] {
  let prev = Char::from_int(c.to_int() - 1)
  if is_valid(prev) {
    return Some(prev)
  }
  None
}

fn Char::from_int(self : Int) -> Char {
  obj_magic(self)
}

