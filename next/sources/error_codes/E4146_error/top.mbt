fn main {
  let value = 1.0
  match value {
    _..<0.0 => println("negative") // Error: Type Double is not supported by range pattern.
    _ => println("zero or positive")
  }
}