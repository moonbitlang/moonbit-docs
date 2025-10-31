enum Color {
  Red
  Green
  Blue
  RGB(Int, Int, Int)
  CMYK(Int, Int, Int, Int)
} derive(Show)

fn print_color(color : Color) -> Unit {
  match color {
    Red => println("Red")
    Green => println("Green")
    Blue => println("Blue")
    // Take the three Int values from RGB and print them.
    RGB(r, g, b) => println("RGB: \{r}, \{g}, \{b}")
    CMYK(c, m, y, k) => println("CMYK: \{c}, \{m}, \{y}, \{k}")
  }
}

fn main {
  let red = Red
  let green = Color::Green
  let blue = RGB(0, 0, 255)
  let black = CMYK(0, 0, 0, 100)
  print_color(red)
  print_color(green)
  print_color(blue)
  print_color(black)
}
