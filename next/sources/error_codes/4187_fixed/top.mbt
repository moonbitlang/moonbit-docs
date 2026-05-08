///|
using @builtin {type Array}

///|
fn length(values : Array[Int]) -> Int {
  values.length()
}

///|
test {
  inspect(length([1, 2]), content="2")
}
