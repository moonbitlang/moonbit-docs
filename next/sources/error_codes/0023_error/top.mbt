///|
fn main {
  println("Hello, world!") catch { // `try` is omitted here
    _ => println("Error")
  }
  try {
    println("Hello, ")
    println("world!")
  } catch {
    _ => println("Error in try block")
  }
}
