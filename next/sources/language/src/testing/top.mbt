/// start test 1
test "test_name" {
  assert_eq(1 + 1, 2)
  assert_eq(2 + 2, 4)
  debug_inspect([1, 2, 3], content="[1, 2, 3]")
}
// end test 1

/// start test 2
test "panic_test" {
  let _ : Int = Option::None.unwrap()
}
// end test 2

/// start snapshot test 1
struct X {
  x : Int
} derive(Debug)

test "show snapshot test" {
  debug_inspect({ x: 10 }, content="{ x: 10 }")
}
// end snapshot test 1

/// start snapshot test 2
enum Rec {
  End
  Really_long_name_that_is_difficult_to_read(Rec)
} derive(Debug, ToJson)

test "json snapshot test" {
  let r = Really_long_name_that_is_difficult_to_read(
    Really_long_name_that_is_difficult_to_read(
      Really_long_name_that_is_difficult_to_read(End),
    ),
  )
  debug_inspect(
    r,
    content="Really_long_name_that_is_difficult_to_read(Really_long_name_that_is_difficult_to_read(Really_long_name_that_is_difficult_to_read(End)))",
  )
  json_inspect(r, content=[
    "Really_long_name_that_is_difficult_to_read",
    [
      "Really_long_name_that_is_difficult_to_read",
      ["Really_long_name_that_is_difficult_to_read", "End"],
    ],
  ])
}
// end snapshot test 2

/// start snapshot test 3
test "record anything" {
  let t = @test.Test("record anything")
  t.write("Hello, world!")
  t.writeln(" And hello, MoonBit!")
  t.snapshot(filename="record_anything.txt")
}
// end snapshot test 3
