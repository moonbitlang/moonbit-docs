struct Point {
  x : Int
  y : Int
} derive(Show)

fn main {
  let tuple = (1, false, 3.14)
  let (a, b, c) = tuple
  println("a:\{a}, b:\{b}, c:\{c}")
  let record = { x: 5, y: 6 }
  let { x, y } = record
  println("x:\{x}, y:\{y}")
}