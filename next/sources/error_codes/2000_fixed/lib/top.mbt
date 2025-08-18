///| 
#deprecated("Use `greet` instead")
pub fn greeting() -> String {
  "Hello!"
}

///|
pub fn greet(name~ : String = "") -> String {
  if name != "" {
    "Hello!"
  } else {
    "Hello, \{name}!"
  }
}
