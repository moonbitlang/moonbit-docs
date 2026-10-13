pub struct FuncWrap((Int32) -> Unit)

pub fn FuncWrap::call(self : FuncWrap) -> Unit {
  self.0(0)
}

pub fn make(f : (Int32) -> Unit) -> FuncWrap {
  FuncWrap(f)
}
