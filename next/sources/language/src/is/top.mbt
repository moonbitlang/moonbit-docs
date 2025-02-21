// start is 1
fn is_none[T](x : T?) -> Bool {
  x is None
}

fn start_with_lower_letter(s: String) -> Bool {
  s is ['a'..='z', ..]
}
// end is 1

// start is 2
fn f(x : Int?) -> Bool {
  x is Some(v) && v >= 0
}
// end is 2

// start is 3
fn g(x : Array[Int?]) -> Unit {
  if x is [v, .. rest] && v is Some(i) && i is 0..=10 {
    println(v)
    println(i)
    println(rest)
  }
}
// end is 3

// start is 4
fn h(x : Int?) -> Unit {
  guard x is Some(v) 
  println(v)
}
// end is 4

// start is 5
fn i(x : Int?) -> Unit {
  let mut m = x
  while m is Some(v) {
    println(v)
    m = None
  }
}
// end is 5
