struct MutPoint {
  mut mx : Int
  y : Int
} derive(Show)

fn main {
  let point = { mx: 3, y: 4 }
  println("point: \{point}")
  point.mx = 10
  println("point: \{point}")
}

