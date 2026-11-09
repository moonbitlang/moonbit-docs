///|
let offset : Int32 = 2

///|
#export_name("add")
pub fn add(a : Int32, b : Int32) -> Int32 {
  a + b + offset
}
