// start derive default struct
struct DeriveDefault {
  x : Int
  y : Option[String]
} derive(Default, Eq, Show)

test "derive default struct" {
  let p = DeriveDefault::default()
  assert_eq!(p, DeriveDefault::{ x: 0, y: None })
}
// end derive default struct

// start derive default enum
enum DeriveDefaultEnum {
  Case1(Int)
  Case2(label~ : String)
  Case3
} derive(Default, Eq, Show)

test "derive default enum" {
  assert_eq!(DeriveDefaultEnum::default(), DeriveDefaultEnum::Case3)
}
// end derive default enum