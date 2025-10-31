///|
/// swap two int in array
fn swap_int(arr : Array[Int]) -> Unit {
  let tmp : Int = arr[0]
  arr[0] = arr[1]
  arr[1] = tmp
}

///|
/// swap two bool in array
fn swap_bool(arr : Array[Bool]) -> Unit {
  let tmp : Bool = arr[0]
  arr[0] = arr[1]
  arr[1] = tmp
}

///|
/// generic swap
fn[T] swap(arr : Array[T]) -> Unit {
  let tmp : T = arr[0]
  arr[0] = arr[1]
  arr[1] = tmp
}

///|
fn main {
  // swap ints
  let array1 = [1, 2]
  swap_int(array1)
  println(array1)

  // swap bools
  let array2 = [true, false]
  swap_bool(array2)
  println(array2)

  // generic swap
  swap(array1)
  swap(array2)
  println(array1)
  println(array2)
}
