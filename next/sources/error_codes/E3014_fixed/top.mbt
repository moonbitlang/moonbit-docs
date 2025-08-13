extern "wasm" fn i32_load(addr : Int) -> Int =
  #|(func (param i32) (result i32)
  #| (i32.load (local.get 0)))