fn main {
  let arr1 : Array[Int] = [1, 2, 3, 4, 5]
  let arr2 = Array::make(4,1) 

  println(arr1.length()) // get the length of the array
  println(arr1[1]) // get the second element of the array

  // We can also use the spread operator to concatenate arrays.
  let arr3 = [..arr1, 1000, 2000, ..arr2, 3000, 4000]
  println("spread arrays:")
  println(arr3)

  let view : ArrayView[Int] = arr1[1:4]
  println("array view:")
  println(view)
  println("view[0]:")
  println(view[0])

  arr1.push(6) // push an element to the end
  println("updated array:")
  println(arr1)
}