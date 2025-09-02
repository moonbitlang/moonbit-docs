///|
pub fn rethrow() -> Unit {
  // Error: Function with error can only be used 
  // inside a function with error types in its signature
  fail("throwing")
}
