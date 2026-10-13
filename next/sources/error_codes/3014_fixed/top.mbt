///|
extern "wasm" fn i32_load(addr : Int32) -> Int32 =
  #|(func (param i32) (result i32)
  #| (i32.load (local.get 0)))

///|
test {
  ignore(i32_load(0))
}
