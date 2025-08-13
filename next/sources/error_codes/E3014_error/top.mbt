extern "wasm" fn i32_load(addr : Int) -> Int = // Error: Inline wasm syntax error: unmatched parenthesis at 1:1-1:57
  #|(func (param i32) (result i32)
  #| (i32.load (local.get 0))