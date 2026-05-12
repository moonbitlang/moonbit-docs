priv struct S {
  v : Int
}

priv trait A {
  value(Self) -> Int
}

priv trait B {
  value(Self) -> Int
}

impl A for S with value(self) {
  self.v
}

impl B for S with value(self) {
  self.v + 1
}

pub fn read() -> Int {
  let s : S = { v: 3 }
  A::value(s) + B::value(s)
}
