// start json basic
struct JsonTest1 {
  x : Int
  y : Int
} derive(FromJson, ToJson, Eq)

pub extend JsonTest1 with @moonbitlang/core/json.FromJson::{from_json}

pub extend JsonTest1 with ToJson::{to_json}

pub extend JsonTest1 with Eq::{not_equal, equal}

enum JsonTest2 {
  A(x~ : Int)
  B(x~ : Int, y~ : Int)
} derive(FromJson(style="legacy"), ToJson(style="legacy"), Eq)

pub extend JsonTest2 with @moonbitlang/core/json.FromJson::{from_json}

pub extend JsonTest2 with ToJson::{to_json}

pub extend JsonTest2 with Eq::{not_equal, equal}

test "json basic" {
  let input = JsonTest1::{ x: 123, y: 456 }
  let expected : Json = { "x": 123, "y": 456 }
  @test.assert_eq(ToJson::to_json(input), expected)
  assert_true(@json.from_json(expected) == input)
  let input = JsonTest2::A(x=123)
  let expected : Json = { "$tag": "A", "x": 123 }
  @test.assert_eq(ToJson::to_json(input), expected)
  assert_true(@json.from_json(expected) == input)
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
)

pub extend JsonTest3 with @moonbitlang/core/json.FromJson::{from_json}

pub extend JsonTest3 with ToJson::{to_json}

pub extend JsonTest3 with Eq::{not_equal, equal}

enum JsonTest4 {
  A(x~ : Int)
  B(x~ : Int, y~ : Int)
} derive(FromJson, ToJson, Eq)

pub extend JsonTest4 with @moonbitlang/core/json.FromJson::{from_json}

pub extend JsonTest4 with ToJson::{to_json}

pub extend JsonTest4 with Eq::{not_equal, equal}

test "json args" {
  let input = JsonTest3::{ x: 123, y: 456 }
  let expected : Json = { "renamedX": 123, "y": 456 }
  @test.assert_eq(ToJson::to_json(input), expected)
  assert_true(@json.from_json(expected) == input)
  let input = JsonTest4::A(x=123)
  let expected : Json = ["A", { "x": 123 }]
  @test.assert_eq(ToJson::to_json(input), expected)
  assert_true(@json.from_json(expected) == input)
}
// end json args

// start json optional
struct A {
  x : Int?
  y : Int??
  z : (Int?, Int??)
} derive(ToJson)

pub extend A with ToJson::{to_json}

test {
  json_inspect({ x: None, y: None, z: (None, None) }, content={
    "z": [null, null],
  })
  json_inspect({ x: Some(1), y: Some(None), z: (Some(1), Some(None)) }, content={
    "x": 1,
    "y": null,
    "z": [[1], [null]],
  })
  json_inspect({ x: Some(1), y: Some(Some(1)), z: (Some(1), Some(Some(1))) }, content={
    "x": 1,
    "y": [1],
    "z": [[1], [[1]]],
  })
}
// end json optional
