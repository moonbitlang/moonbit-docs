///|
struct Point {
  x : Int
  y : Int
} derive(Show, Eq, Compare, @quickcheck.Arbitrary)

///|
// start map inplace ffi declaration
#borrow(xs, call, closure)
extern "c" fn ffi_map_inplace(
  xs : FixedArray[Point],
  call : FuncRef[((Point) -> Point, Point) -> Point],
  closure : (Point) -> Point,
) = "ffi_map_inplace"
// end map inplace ffi declaration

///|
// start map inplace wrapper
fn map_inplace(xs : FixedArray[Point], closure : (Point) -> Point) -> Unit {
  ffi_map_inplace(xs, fn(f, x) { f(x) }, closure)
}
// end map inplace wrapper

///|
test "map_inplace functionality" {
  let xs : FixedArray[Point] = @quickcheck.samples(4) |> FixedArray::from_array
  let mut i = 0
  fn f(x) {
    // Note: i increments on each call, but we can't use inspect inside closure
    i += 1
    x
  }

  inspect(i, content="0")
  map_inplace(xs, f)
  inspect(
    xs,
    content="[{x: 0, y: 0}, {x: 0, y: 0}, {x: 0, y: -1}, {x: 2, y: 0}]",
  )
  inspect(i, content="8")
  map_inplace(xs, f)
  inspect(
    xs,
    content="[{x: 0, y: 0}, {x: 0, y: 0}, {x: 0, y: -1}, {x: 2, y: 0}]",
  )
  inspect(i, content="16")
  map_inplace(xs, f)
  inspect(
    xs,
    content="[{x: 0, y: 0}, {x: 0, y: 0}, {x: 0, y: -1}, {x: 2, y: 0}]",
  )
  inspect(i, content="24")
}
