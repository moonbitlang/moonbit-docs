///|
pub let a : Ref[Int32?] = Ref(None)

///|
fn init {
  a.val = Some(f())
}

///|
fn f() -> Int32 {
  a.val.unwrap()
}
