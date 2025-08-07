// expand wildcard

///|
priv enum T {
  A
  B
  C
}

///|
pub fn f() -> Unit {
  match T::A {
    B => ()
    C => ()
    A => ()
  }
}
// end expand wildcard

///|
test {
  let _ = T::B
  let _ = T::C

}

// make public

///|
pub enum T2 {
  A
  B
  C
}

///|
pub fn T2::new(value : Int) -> T2 {
  match value {
    0 => T2::A
    1 => T2::B
    _ => T2::C
  }
}
// end make public

// make all public

///|
pub(all) enum T3 {
  A
  B
  C
}
// end make all public

// remove unused

///|
priv enum T4 {
  A
}

///|
pub fn g() -> Unit {
  match T4::A {
    A => ()
  }
}
// end remove unused
