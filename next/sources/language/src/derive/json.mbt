// start json basic
struct JsonTest1 {
  x : Int
  y : Int
} derive(FromJson, ToJson, Eq, Show)

enum JsonTest2 {
  A(x~ : Int)
  B(x~ : Int, y~ : Int)
} derive(FromJson, ToJson, Eq, Show)

test "json basic" {
  let input = JsonTest1::{ x: 123, y: 456 }
  let expected : Json = { "x": 123, "y": 456 }
  assert_eq(input.to_json(), expected)
  assert_eq(@json.from_json(expected), input)
  let input = JsonTest2::A(x=123)
  let expected : Json = { "$tag": "A", "x": 123 }
  assert_eq(input.to_json(), expected)
  assert_eq(@json.from_json(expected), input)
}
// end json basic

// start json args
struct JsonTest3 {
  x : Int
  y : Int
} derive (
  FromJson(fields(x(rename="renamedX"))),
  ToJson(fields(x(rename="renamedX"))),
  Eq,
  Show,
)

enum JsonTest4 {
  A(x~ : Int)
  B(x~ : Int, y~ : Int)
} derive (
  FromJson(rename_fields="SCREAMING_SNAKE_CASE", repr(ext_tagged)),
  ToJson(rename_fields="SCREAMING_SNAKE_CASE", repr(ext_tagged)),
  Eq,
  Show,
)

test "json args" {
  let input = JsonTest3::{ x: 123, y: 456 }
  let expected : Json = { "renamedX": 123, "y": 456 }
  assert_eq(input.to_json(), expected)
  assert_eq(@json.from_json(expected), input)
  let input = JsonTest4::A(x=123)
  let expected : Json = { "A": { "X": 123 } }
  assert_eq(input.to_json(), expected)
  assert_eq(@json.from_json(expected), input)
}
// end json args
