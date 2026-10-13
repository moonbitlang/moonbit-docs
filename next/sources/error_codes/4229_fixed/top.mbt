///|
declare pub fn new_name() -> Int32

///|
declare pub fn old_name() -> Int32

///|
#alias(old_name)
pub fn new_name() -> Int32 {
  42
}
