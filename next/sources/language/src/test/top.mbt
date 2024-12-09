// start test 1
test "test_name" {
  assert_eq!(1 + 1, 2)
  assert_eq!(2 + 2, 4)
  inspect!([1, 2, 3], content="[1, 2, 3]")
}
// end test 1

// start test 2
test "panic_test" {
  let _ : Int = Option::None.unwrap()

}
// end test 2
