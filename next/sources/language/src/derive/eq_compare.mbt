// start derive eq_compare struct
struct DeriveEqCompare {
  x : Int
  y : Int
} derive(Eq, Compare)

test "derive eq_compare struct" {
  let p1 = DeriveEqCompare::{ x: 1, y: 2 }
  let p2 = DeriveEqCompare::{ x: 2, y: 1 }
  let p3 = DeriveEqCompare::{ x: 1, y: 2 }
  let p4 = DeriveEqCompare::{ x: 1, y: 3 }

  // Eq
  assert_eq!(p1 == p2, false)
  assert_eq!(p1 == p3, true)
  assert_eq!(p1 == p4, false)

  assert_eq!(p1 != p2, true)
  assert_eq!(p1 != p3, false)
  assert_eq!(p1 != p4, true)

  // Compare
  assert_eq!(p1 < p2, true)
  assert_eq!(p1 < p3, false)
  assert_eq!(p1 < p4, true)
  assert_eq!(p1 > p2, false)
  assert_eq!(p1 > p3, false)
  assert_eq!(p1 > p4, false)
  assert_eq!(p1 <= p2, true)
  assert_eq!(p1 >= p2, false)
}
// end derive eq_compare struct

// start derive eq_compare enum
enum DeriveEqCompareEnum {
  Case1(Int)
  Case2(label~ : String)
  Case3
} derive(Eq, Compare)

test "derive eq_compare enum" {
  let p1 = DeriveEqCompareEnum::Case1(42)
  let p2 = DeriveEqCompareEnum::Case1(43)
  let p3 = DeriveEqCompareEnum::Case1(42)
  let p4 = DeriveEqCompareEnum::Case2(label="hello")
  let p5 = DeriveEqCompareEnum::Case2(label="world")
  let p6 = DeriveEqCompareEnum::Case2(label="hello")
  let p7 = DeriveEqCompareEnum::Case3

  // Eq
  assert_eq!(p1 == p2, false)
  assert_eq!(p1 == p3, true)
  assert_eq!(p1 == p4, false)

  assert_eq!(p1 != p2, true)
  assert_eq!(p1 != p3, false)
  assert_eq!(p1 != p4, true)

  // Compare
  assert_eq!(p1 < p2, true) // 42 < 43
  assert_eq!(p1 < p3, false)
  assert_eq!(p1 < p4, true) // Case1 < Case2
  assert_eq!(p4 < p5, true)
  assert_eq!(p4 < p6, false)
  assert_eq!(p4 < p7, true) // Case2 < Case3
}
// end derive eq_compare enum
