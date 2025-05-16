enum Color {
  Blue
  Red
  Green
  RGB(Int, Int, Int)
  RGBA(Int, Int, Int, Int)
} derive(Show)

fn get_green(color : Color) -> Int {
  match color {
    Blue | Red => 0
    Green => 255
    RGB(_, g, _) | RGBA(_, g, _, _) => g
  }
}

fn main {
  println("The green part of Red is \{get_green(Red)}")
  println("The green part of Green is \{get_green(Green)}")
  println("The green part of Blue is \{get_green(Blue)}")
  println("The green part of RGB(0,0,0) is \{get_green(RGB(0,0,0))}")
  println("The green part of RGBA(50,5,0,6) is \{get_green(RGBA(50,5,0,6))}")
}
