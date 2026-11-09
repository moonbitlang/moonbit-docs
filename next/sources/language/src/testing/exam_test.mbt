// start exam traits
#derive(Eq, Debug)
enum ExamResult {
  Pass
  Fail
}
// end exam traits

///|
test "exam result assertions" {
  assert_eq(ExamResult::Pass, Pass)
  assert_true(ExamResult::Pass != Fail)
}
