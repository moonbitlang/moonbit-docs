///|
using @builtin {Array}

///|
fn length(values : Array[Int32]) -> Int32 {
  values.length()
}

///|
test {
  ignore(length)
}
