///|
#callsite(autofill(parameter))
fn f(parameter~ : Int) -> Unit {
  // ^~~~~~~~~ Error: Cannot auto-fill parameter of type Int
}
