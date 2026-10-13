///|
extern "wasm" fn i32_load(
  addr : Int32, // Error: Inline wasm syntax error: unmatched parenthesis at 1:1-1:57
) -> Int32 =
  #|(func (param i32) (result i32)
  #| (i32.load (local.get 0))
