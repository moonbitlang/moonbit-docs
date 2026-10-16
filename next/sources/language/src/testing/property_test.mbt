///|
/// start property check
test "adding zero preserves an integer" {
  @quickcheck.check((x : Int32) => x + 0 == x, count=100, seed=2026)
}
// end property check

///|
/// start property report
test "adding one does not always increase an integer" {
  let report = @quickcheck.report(
    (x : Int32) => x + 1 > x,
    count=100,
    seed=2026,
  )
  debug_inspect(
    report,
    content=(
      #|Falsified(
      #|  counterexample=2147483647,
      #|  tests=99,
      #|  size=98,
      #|  shrinks=0,
      #|  shrink_attempts=31,
      #|)
    ),
  )
}
// end property report

///|
/// start property regression
test "adding one at the Int32 boundary" {
  let x : Int32 = 2147483647
  assert_eq(x + 1, -2147483648)
  assert_eq(x.to_int64() + 1, 2147483648L)
}
// end property regression
