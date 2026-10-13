///|
extern "js" fn int_id(x : Int32) -> Int32 = "(x) => x"

///|
pub fn concrete_id(x : Int32) -> Int32 {
  int_id(x)
}
