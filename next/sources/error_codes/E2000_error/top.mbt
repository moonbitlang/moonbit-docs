/// @alert deprecated "Use `greet` instead"
fn greeting() -> String {
  "Hello!"
}

fn greet(name~ : String = "") -> String {
  if name != "" {
    "Hello!"
  } else {
    "Hello, \{name}!"
  }
}

fn main {
  println(greeting())
  //      ^~~~~~~~ Warning (Alert deprecated): Use `greet` instead(2000)
}