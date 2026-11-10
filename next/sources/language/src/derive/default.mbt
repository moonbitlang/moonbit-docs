// start derive default struct
#derive(Default, Eq)
struct DeriveDefault {
  x : Int32
  y : String?
}

pub extend DeriveDefault with Default::{default}

pub extend DeriveDefault with Eq::{not_equal, equal}

test "derive default struct" {
  let p : DeriveDefault = Default::default()
  assert_true(p == DeriveDefault::{ x: 0, y: None })
}
// end derive default struct

// start derive default enum
#derive(Default, Eq)
enum DeriveDefaultEnum {
  Case1(Int32)
  Case2(label~ : String)
  Case3
}

pub extend DeriveDefaultEnum with Default::{default}

pub extend DeriveDefaultEnum with Eq::{not_equal, equal}

test "derive default enum" {
  let value : DeriveDefaultEnum = Default::default()
  assert_true(value == DeriveDefaultEnum::Case3)
}
// end derive default enum
