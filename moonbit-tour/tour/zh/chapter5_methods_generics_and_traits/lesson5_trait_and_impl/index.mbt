///|
trait Equal {
  is_equal(Self, Self) -> Bool
}

///|
impl Equal for Int with is_equal(a, b) {
  a == b
}

///|
struct Pos(Int, Int)

///|
impl Equal for Pos with is_equal(a, b) {
  let Pos(x1, y1) = a
  let Pos(x2, y2) = b
  x1 == x2 && y1 == y2
}

///|
fn main {
  println(Equal::is_equal(1, 1))
  println(Equal::is_equal(1, 2))
  let pos1 = Pos(1, 2)
  let pos2 = Pos(1, 2)
  let pos3 = Pos(4, 5)
  println(Equal::is_equal(pos1, pos2))
  println(Equal::is_equal(pos2, pos3))
}
