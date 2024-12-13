struct Point {
  x : Int
  y : Int
} derive(Show)

fn main {
  let tuple = (1, false, 3.14)
  let array = [1, 2, 3]
  let record = { x: 5, y: 6 }
  let (a, b, c) = tuple
  println("a:\{a}, b:\{b}, c:\{c}")
  let [d, e, f] = array
  println("d:\{d}, e:\{e}, f:\{f}")
  let { x, y } = record
  println("x:\{x}, y:\{y}")
}
