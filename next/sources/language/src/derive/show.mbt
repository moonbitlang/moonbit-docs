// start derive show struct
struct MyStruct {
  x : Int
  y : Int
} derive(Show)

test "derive show struct" {
  let p = MyStruct::{ x: 1, y: 2 }
  assert_eq!(Show::to_string(p), "{x: 1, y: 2}")
}
// end derive show struct

// start derive show enum
enum MyEnum {
  Case1(Int)
  Case2(label~ : String)
  Case3
} derive(Show)

test "derive show enum" {
  assert_eq!(Show::to_string(MyEnum::Case1(42)), "Case1(42)")
  assert_eq!(
    Show::to_string(MyEnum::Case2(label="hello")),
    "Case2(label=\"hello\")",
  )
  assert_eq!(Show::to_string(MyEnum::Case3), "Case3")
}
// end derive show enum
