fn main {
  let array = [1, 2, 3]

  println("for loop:")
  for i = 0; i < array.length(); i = i + 1 {
    println("array[\{i}]: \{array[i]}")
  }

  println("\nwhile loop:")
  let mut j = 0
  while true {
    println("array[\{j}]: \{array[j]}")
    j = j + 1
    if j < array.length() {
      continue
    } else {
      break
    }
  }
}
