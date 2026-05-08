///|
using @builtin {Array}

///|
fn length(values : Array[Int]) -> Int {
  values.length()
}

///|
test {
  ignore(length)
}
