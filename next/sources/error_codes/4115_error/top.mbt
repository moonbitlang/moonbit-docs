///|
#callsite(autofill(parameter))
fn f(parameter~ : Int32) -> Unit {
  // ^~~~~~~~~ Error: Cannot auto-fill parameter of type Int32
}
