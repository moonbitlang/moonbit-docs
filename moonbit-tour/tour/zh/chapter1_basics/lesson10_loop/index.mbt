fn main {
  let array = [1, 2, 3]

  println("for loop:")
  for i = 0; i < array.length(); i = i + 1 {
    println("array[\{i}]: \{array[i]}")
  }

  println("\nfunctional for loop:")

  let sum = for i = 1, acc = 0; i <= 10; i = i + 1 {
    let even = i % 2 == 0
    continue i + 1, acc + i
  } else {
    acc
  }
  println(sum)

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
