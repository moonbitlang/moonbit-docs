// start is 1
fn[T] is_none(x : T?) -> Bool {
  x is None
}

fn start_with_lower_letter(s : String) -> Bool {
  s is ['a'..<='z', ..]
}
// end is 1

// start is 2
fn f(x : Int32?) -> Bool {
  x is Some(v) && v >= 0
}
// end is 2

// start is 3
fn g(x : Array[Int32?]) -> Unit {
  if x is [v, .. rest] && v is Some(i) && i is (0..<=10) {
    debug(v)
    println(i)
    debug(rest)
  }
}
// end is 3

// start is 4
fn h(x : Int32?) -> Unit {
  guard! x is Some(v)
  println(v)
}
// end is 4

// start is 5
fn i(x : Int32?) -> Unit {
  let mut m = x
  while m is Some(v) {
    println(v)
    m = None
  }
}
// end is 5

// start is 6
fn j(x : Int32) -> Int32? {
  Some(x)
}

fn init {
  guard! j(42) is (Some(a) as b)
  println(a)
  debug(b)
}
// end is 6
