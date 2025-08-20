///|
// start ffi declaration
#borrow(call, closure)
extern "c" fn ffi_register_callback(
  call : FuncRef[(() -> Unit) -> Unit],
  closure : () -> Unit,
) = "register_callback"
// end ffi declaration

///|
// start wrapper function
fn register_callback(closure : () -> Unit) -> Unit {
  ffi_register_callback(
    fn(f) { f() }, // moonc know how to consume `closure`
    closure,
  )
}
// end wrapper function

///|
// start test case
test "register_callback functionality" {
  let output = StringBuilder::new()
  let s1 = "moonbit"
  inspect(s1, content="moonbit") // capture free variables before registering
  register_callback(fn() {
    output.write_string(s1)
    output.write_char('\n')
  })
  let s2 = "apple"
  register_callback(fn() {
    output.write_string(s2)
    output.write_char('\n')
  })
  inspect(
    output,
    content=(
      #|moonbit
      #|moonbit
      #|moonbit
      #|apple
      #|apple
      #|apple
      #|
    ),
  )
}
// end test case
