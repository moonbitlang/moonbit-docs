fn main {
  try {
    may_raise_error!(42)
  } catch {
    error => println("Error: \{error}")
  }
}