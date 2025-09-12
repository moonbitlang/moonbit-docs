fn main {
  let str = "Hello, World!"
  // Access a character by index.
  let c : Char = str.get_char(4).unwrap()
  println(c)
  let c2 = 'o'
  println(c == c2)

  // Use escape sequence.
  println("\nHello, \tWorld!")
  println("unicode \u{1F407} is a rabbit")

  // Concatenate two strings.
  println(str + " Hello, MoonBit!")

  // Use string interpolation.
  let moon = "Moon"
  let bit = "Bit"
  println("Use \{moon + bit}. Happy coding")
}
