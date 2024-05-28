pub type JS_String

fn string_load_ffi(offset : Int, length : Int) -> JS_String = "string" "load"

fn string_store_ffi(string : JS_String, offset : Int) = "string" "store"

pub fn length(self : JS_String) -> Int = "string" "length"

pub fn log(self : JS_String) = "string" "log"

pub fn JS_String::empty() -> JS_String = "string" "empty"

pub fn JS_String::from_string(str : String) -> Option[JS_String] {
  if str.length() == 0 {
    return Some(JS_String::empty())
  }
  let memory = @memory.allocate(str.length() * 2)?
  memory.store_bytes(str.to_bytes())
  let str = string_load_ffi(memory.offset, str.length())
  memory.free()?
  Some(str)
}

pub fn JS_String::to_string(str : JS_String) -> Option[String] {
  if str.length() == 0 {
    return Some("")
  }
  let memory = @memory.allocate(str.length() * 2)?
  string_store_ffi(str, memory.offset)
  let str = memory.load_bytes().to_string()
  memory.free()?
  Some(str)
}
