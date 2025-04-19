///|
extern "c" fn ffi_register_callback(
  call : FuncRef[(() -> Unit) -> Unit],
  closure : () -> Unit
) = "register_callback"

///|
fn register_callback(closure : () -> Unit) -> Unit {
  ffi_register_callback(
    fn(f) { f() }, // moonc know how to consume `closure`
    closure,
  )
}

///|
extern "c" fn ffi_register_callback_with_point(
  call : FuncRef[((Int, Int) -> Int, Int, Int) -> Int],
  closure : (Int, Int) -> Int
) -> Int = "register_callback_with_point"

///|
fn register_callback_with_point(closure : (Int, Int) -> Int) -> Int {
  ffi_register_callback_with_point(
    fn(f, x, y) { f(x, y) }, // moonc know how to consume `closure`
    closure,
  )
}

///|
fn main {
  let s1 = "moonbit"
  let s2 = "mooncake"
  register_callback(fn() {
    println(s1) // capture free variables
  })
  let res = register_callback_with_point(fn(x, y) {
    println(s2) // capture free variables
    (x * x + y * y).to_double().sqrt().to_int()
  })
  println(res)
}
