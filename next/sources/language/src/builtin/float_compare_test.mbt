///|
test "total comparison with NaN" {
  let nan = 0.0 / 0.0
  assert_false(nan == nan)
  assert_eq(Double::total_compare(nan, -1.0 / 0.0), -1)
  assert_eq(Double::total_compare(nan, nan), 0)
  assert_eq(Double::total_compare(-0.0, 0.0), 0)
}
