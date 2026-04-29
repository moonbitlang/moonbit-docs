// start derive debug struct
struct DebugPoint {
  x : Int
  y : Int
} derive(Debug)

test "derive debug struct" {
  let point = DebugPoint::{ x: 1, y: 2 }
  debug_inspect(point, content="{ x: 1, y: 2 }")
}
// end derive debug struct

// start derive debug enum
enum DebugShape {
  Circle(radius~ : Int)
  Rect(width~ : Int, height~ : Int)
} derive(Debug)

test "derive debug enum" {
  let shape = DebugShape::Rect(width=3, height=4)
  debug_inspect(shape, content="Rect(width=3, height=4)")
}
// end derive debug enum
