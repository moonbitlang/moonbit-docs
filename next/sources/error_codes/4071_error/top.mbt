pub(all) struct MyArray[T](Array[T])

#intrinsic("%array.get")
#intrinsic("%fixedarray.get")
pub fn[T] MyArray::get(self : MyArray[T], index : Int) -> T {
  self.0[index]
}
