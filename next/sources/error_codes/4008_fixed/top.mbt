///|
extern "js" fn int_id(x : Int) -> Int = "(x) => x"

///|
pub fn concrete_id(x : Int) -> Int {
  int_id(x)
}
