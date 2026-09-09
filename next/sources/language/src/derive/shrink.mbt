// start derive shrink struct
///|
struct ShrinkPoint {
  x : Int
  y : Int
} derive(Shrink)

///|
fn shrink_candidates(point : ShrinkPoint) -> Iter[ShrinkPoint] {
  @quickcheck.Shrink::shrink(point)
}

///|
test "derive shrink struct" {
  let candidates = shrink_candidates(ShrinkPoint::{ x: 10, y: 20, }).collect()
  assert_true(candidates.length() > 0)
}
// end derive shrink struct
