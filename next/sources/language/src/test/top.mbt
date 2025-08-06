// start test 1
test "test_name" {
  assert_eq(1 + 1, 2)
  assert_eq(2 + 2, 4)
  inspect([1, 2, 3], content="[1, 2, 3]")
}
// end test 1

// start test 2
test "panic_test" {
  let _ : Int = Option::None.unwrap()

}
// end test 2

// start snapshot test 1
struct X {
  x : Int
} derive(Show)

test "show snapshot test" {
  inspect({ x: 10 }, content="{x: 10}")
}
// end snapshot test 1

// start snapshot test 2
enum Rec {
  End
  Really_long_name_that_is_difficult_to_read(Rec)
} derive(Show, ToJson(style="legacy"))

test "json snapshot test" {
  let r = Really_long_name_that_is_difficult_to_read(
    Really_long_name_that_is_difficult_to_read(
      Really_long_name_that_is_difficult_to_read(End),
    ),
  )
  inspect(
    r,
    content="Really_long_name_that_is_difficult_to_read(Really_long_name_that_is_difficult_to_read(Really_long_name_that_is_difficult_to_read(End)))",
  )
  @json.inspect(r, content={
    "$tag": "Really_long_name_that_is_difficult_to_read",
    "0": {
      "$tag": "Really_long_name_that_is_difficult_to_read",
      "0": {
        "$tag": "Really_long_name_that_is_difficult_to_read",
        "0": { "$tag": "End" },
      },
    },
  })
}
// end snapshot test 2

// start snapshot test 3
test "record anything" (t : @test.T) {
  t.write("Hello, world!")
  t.writeln(" And hello, MoonBit!")
  t.snapshot(filename="record_anything.txt")
}
// end snapshot test 3
