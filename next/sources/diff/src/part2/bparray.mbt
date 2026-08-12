///|
struct BPArray[T](Array[T]) // BiPolar Array

///|
fn[T] BPArray::make(capacity : Int, default : T) -> BPArray[T] {
  let arr = Array::make(capacity, default)
  BPArray(arr)
}

///|
fn[T] BPArray::copy(self : BPArray[T]) -> BPArray[T] {
  let BPArray(arr) = self
  BPArray(arr.copy())
}

///|
#alias("_[_]")
fn[T] BPArray::get(self : BPArray[T], idx : Int) -> T {
  let BPArray(arr) = self
  if idx < 0 {
    arr[arr.length() + idx]
  } else {
    arr[idx]
  }
}

///|
#alias("_[_]=_")
fn[T] BPArray::set(self : BPArray[T], idx : Int, elem : T) -> Unit {
  let BPArray(arr) = self
  if idx < 0 {
    arr[arr.length() + idx] = elem
  } else {
    arr[idx] = elem
  }
}

///|
test "bparray" {
  let foo = BPArray::make(10, "foo")
  let foo2 = foo.copy()
  foo[9] = "bar"
  foo[8] = "baz"
  assert_eq(foo[-1], "bar")
  assert_eq(foo[-2], "baz")
  assert_eq(foo2[-1], "foo")
}
