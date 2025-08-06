// start json basic
struct JsonTest1 {
  x : Int
  y : Int
} derive(FromJson, ToJson, Eq, Show)

enum JsonTest2 {
  A(x~ : Int)
  B(x~ : Int, y~ : Int)
} derive(FromJson(style="legacy"), ToJson(style="legacy"), Eq, Show)

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
  FromJson(style="flat"),
  ToJson(style="flat"),
  Eq,
  Show,
)

test "json args" {
  let input = JsonTest3::{ x: 123, y: 456 }
  let expected : Json = { "renamedX": 123, "y": 456 }
  assert_eq(input.to_json(), expected)
  assert_eq(@json.from_json(expected), input)
  let input = JsonTest4::A(x=123)
  let expected : Json = [ "A", 123 ]
  assert_eq(input.to_json(), expected)
  assert_eq(@json.from_json(expected), input)
}
// end json args



enum E {
  One
  Uniform(Int)
  Axes(x~: Int, y~: Int)
} derive(FromJson(style="legacy"), ToJson(style="legacy"), Eq, Show)

enum EFlat {
  One
  Uniform(Int)
  Axes(x~: Int, y~: Int)
} derive(FromJson(style="flat"), ToJson(style="flat"), Eq, Show)

test "enum legacy style" {
  // Test One variant
  let input = E::One
  let expected : Json = { "$tag": "One" }
  assert_eq(input.to_json(), expected)
  assert_eq(@json.from_json(expected), input)
  
  // Test Uniform variant
  let input = E::Uniform(2)
  let expected : Json = { "$tag": "Uniform", "0": 2 }
  assert_eq(input.to_json(), expected)
  assert_eq(@json.from_json(expected), input)
  
  // Test Axes variant
  let input = E::Axes(x=-1, y=1)
  let expected : Json = { "$tag": "Axes", "x": -1, "y": 1 }
  assert_eq(input.to_json(), expected)
  assert_eq(@json.from_json(expected), input)
}

test "enum flat style" {
  // Test One variant
  let input = EFlat::One
  let expected : Json = "One"
  assert_eq(input.to_json(), expected)
  assert_eq(@json.from_json(expected), input)
  
  // Test Uniform variant
  let input = EFlat::Uniform(2)
  let expected : Json = [ "Uniform", 2 ]
  assert_eq(input.to_json(), expected)
  assert_eq(@json.from_json(expected), input)
  
  // Test Axes variant
  let input = EFlat::Axes(x=-1, y=1)
  let expected : Json = [ "Axes", -1, 1 ]
  assert_eq(input.to_json(), expected)
  assert_eq(@json.from_json(expected), input)
}