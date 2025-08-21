///|
struct Point {
  x : Int
  y : Int
} derive(@quickcheck.Arbitrary, Compare, Eq, Show)

///|
// start closure qsort ffi declaration
#borrow(xs, comp, closure)
extern "c" fn ffi_qsort(
  xs : FixedArray[Point],
  comp : FuncRef[((Point, Point) -> Int, Point, Point) -> Int],
  closure : (Point, Point) -> Int,
) = "fqc_ffi_qsort"
// end closure qsort ffi declaration

///|
// start closure qsort wrapper
fn qsort(xs : FixedArray[Point], comp : (Point, Point) -> Int) -> Unit {
  ffi_qsort(xs, fn(f, x, y) { f(x, y) }, comp)
}
// end closure qsort wrapper

///|
test "qsort_closure functionality" {
  let xs : FixedArray[Point] = @quickcheck.samples(10) |> FixedArray::from_array
  let ys = xs.copy()
  let mut i = 0
  let comp : (Point, Point) -> Int = fn(x, y) {
    i += 1
    // Note: can't use inspect inside closure due to error handling
    x.compare(y)
  }
  inspect(
    xs,
    content="[{x: 0, y: 0}, {x: 0, y: 0}, {x: 0, y: -1}, {x: 2, y: 0}, {x: -2, y: 2}, {x: 0, y: 2}, {x: -5, y: -2}, {x: 2, y: 3}, {x: 3, y: 7}, {x: 1, y: 0}]",
  )
  inspect(
    ys,
    content="[{x: 0, y: 0}, {x: 0, y: 0}, {x: 0, y: -1}, {x: 2, y: 0}, {x: -2, y: 2}, {x: 0, y: 2}, {x: -5, y: -2}, {x: 2, y: 3}, {x: 3, y: 7}, {x: 1, y: 0}]",
  )
  inspect(i, content="0")
  xs |> qsort(comp)
  ys.sort()
  inspect(
    xs,
    content="[{x: -5, y: -2}, {x: -2, y: 2}, {x: 0, y: -1}, {x: 0, y: 0}, {x: 0, y: 0}, {x: 0, y: 2}, {x: 1, y: 0}, {x: 2, y: 0}, {x: 2, y: 3}, {x: 3, y: 7}]",
  )
  inspect(
    ys,
    content="[{x: -5, y: -2}, {x: -2, y: 2}, {x: 0, y: -1}, {x: 0, y: 0}, {x: 0, y: 0}, {x: 0, y: 2}, {x: 1, y: 0}, {x: 2, y: 0}, {x: 2, y: 3}, {x: 3, y: 7}]",
  )
  assert_eq(xs, ys)
}
