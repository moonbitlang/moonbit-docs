pub struct FuncWrap((Int) -> Unit)

pub fn FuncWrap::call(self : FuncWrap) -> Unit {
  self.0(0)
}

pub fn make(f : (Int) -> Unit) -> FuncWrap {
  FuncWrap(f)
}
