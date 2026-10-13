///|
using @builtin {type Array}

///|
fn length(values : Array[Int32]) -> Int32 {
  values.length()
}

///|
test {
  inspect(length([1, 2]), content="2")
}
