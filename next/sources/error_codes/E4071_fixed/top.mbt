/// @intrinsic %array.get
fn MyArray::get[T](self : MyArray[T], index : Int) -> T {
  return self._[index]
}