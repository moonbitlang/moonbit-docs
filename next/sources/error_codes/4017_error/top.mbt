priv struct S {
  v : Int32
}

priv trait A {
  value(Self) -> Int32
}

priv trait B {
  value(Self) -> Int32
}

impl A for S with value(self) {
  self.v
}

impl B for S with value(self) {
  self.v + 1
}

pub fn read() -> Int32 {
  let s : S = { v: 3 }
  s.value()
}
