///|
extern type ConstPtr[T]

// TODO
// pub fn ConstPtr::op_get[T](self : ConstPtr[T], index : Int) -> T = "%fixedarray.unsafe_get"
///|
extern "c" fn ConstPtr::read_int(self : ConstPtr[Int], index : Int) -> Int = "ffi_read_int"

///|
fn ConstPtr::deref_int(self : ConstPtr[Int]) -> Int {
  self.read_int(0)
}

///|
#borrow(xs, count, elem_size, comp)
extern "c" fn qsort_ffi(
  xs : FixedArray[Int],
  count : UInt64,
  elem_size : UInt64,
  comp : FuncRef[(ConstPtr[Int], ConstPtr[Int]) -> Int]
) = "qsort"

///|
fn qsort(
  xs : FixedArray[Int],
  comp : FuncRef[(ConstPtr[Int], ConstPtr[Int]) -> Int]
) -> Unit {
  qsort_ffi(xs, xs.length().to_uint64(), 4UL, comp)
}

///|
test {
  let xs : FixedArray[Int] = @quickcheck.samples(10) |> FixedArray::from_array
  let ys = xs.copy()
  let comp : FuncRef[(ConstPtr[Int], ConstPtr[Int]) -> Int] = fn(x, y) {
    x.deref_int().compare(y.deref_int())
  }
  inspect!(xs, content="[0, 0, 0, -1, -1, 0, 0, -1, 2, 5]")
  inspect!(ys, content="[0, 0, 0, -1, -1, 0, 0, -1, 2, 5]")
  xs |> qsort(comp)
  ys.sort()
  inspect!(xs, content="[-1, -1, -1, 0, 0, 0, 0, 0, 2, 5]")
  inspect!(ys, content="[-1, -1, -1, 0, 0, 0, 0, 0, 2, 5]")
  assert_eq!(xs, ys)
}
