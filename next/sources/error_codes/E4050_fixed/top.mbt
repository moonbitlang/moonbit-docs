pub let a : Ref[Int?] = Ref::new(None)

fn init {
  a.val = Some(f())
}

fn f() -> Int {
  a.val.unwrap()
}