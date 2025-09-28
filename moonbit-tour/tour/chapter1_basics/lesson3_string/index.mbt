///|
fn main {
  let a : String = "Hello, world!"
  let b : Char = 'H'
  println(a)
  println(b)

  // Use escape sequence.
  println("\nHello, \tWorld!")
  println("unicode \u{1F407} is a rabbit")
  println('\u{1F96E}')

  // Concatenate two strings.
  let moon = "Moon"
  let bit = "Bit"
  let moonbit = moon + bit
  println(" Hello," + moonbit)

  // Use string interpolation.
  println("Use \{moon}\{bit}. Happy coding")
}
