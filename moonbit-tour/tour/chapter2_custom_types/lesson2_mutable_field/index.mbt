struct MutPoint {
  mut mx : Int
  y : Int
} derive(Debug)

fn main {
  let point = { mx: 3, y: 4 }
  println("point: \{to_repr(point)}")
  point.mx = 10
  println("point: \{to_repr(point)}")
}
