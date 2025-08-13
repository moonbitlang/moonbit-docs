// unmatched parenthesis
extern "wasm" fn f() =
  #| (func $f

extern "wasm" fn g() =
  #| (func $g (call $does_not_exist))
