///|
fn[T : Show] swap(arr : Array[T]) -> Unit {
  let tmp_str = arr[0].to_string()
  let arr1_str = arr[1].to_string()
  println("swap \{tmp_str} and \{arr1_str} in array.")
  // 和上面的代码等价:
  // println("swap \{arr[0]} and \{arr[1]} in array.") 
  let tmp : T = arr[0]
  arr[0] = arr[1]
  arr[1] = tmp
}

///|
fn[T : Eq + Show] find_index(array : Array[T], target : T) -> Int? {
  for index, elem in array {
    if Eq::equal(elem, target) {
      println("array[\{index}] = \{elem}, \{elem} == \{target}")
      return Some(index)
    } else {
      println("array[\{index}] = \{elem}, \{elem} != \{target}")
    }
  }
  return None
}

///|
fn main {
  let ints = [2, 1, 3, 4, 5]
  swap(ints)
  let j = find_index(ints, 4)
  println("the result is \{j}")
  let i = find_index([true, false, true, false], false)
  println("the result is \{i}")
}
