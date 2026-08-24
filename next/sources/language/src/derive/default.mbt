// start derive default struct
struct DeriveDefault {
  x : Int
  y : String?
} derive(Default, Eq)

test "derive default struct" {
  let p : DeriveDefault = Default::default()
  assert_true(p == DeriveDefault::{ x: 0, y: None })
}
// end derive default struct

// start derive default enum
enum DeriveDefaultEnum {
  Case1(Int)
  Case2(label~ : String)
  Case3
} derive(Default, Eq)

test "derive default enum" {
  let value : DeriveDefaultEnum = Default::default()
  assert_true(value == DeriveDefaultEnum::Case3)
}
// end derive default enum
