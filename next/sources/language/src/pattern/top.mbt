struct User {
  id : String
  name : String
  email : String
}

let user : Unit = {
  let u = { id: "1", name: "John", email: "john@example.com" }
  // start pattern 1
  let id = match u {
    { id, name: _, email: _ } => id
  }

  // <=>
  let { id, name: _, email: _ } = u

  // <=>
  let { id, .. } = u
  // end pattern 1

}

// start pattern 2
test {
  let ary = [1, 2, 3, 4]
  if ary is [a, b, ..rest] && a == 1 && b == 2 && rest.length() == 2{
    inspect!("a = \{a}, b = \{b}", content="a = 1, b = 2")
  } else {
    fail!("")
  }
  guard ary is [.., a, b] else { fail!("") }
  inspect!("a = \{a}, b = \{b}", content="a = 3, b = 4")
}
// end pattern 2

// start array pattern 1
test {
  fn palindrome(s: String) -> Bool {
    loop s.view() {
      [] | [_] => true
      [a, ..rest, b] => if a == b { continue rest } else { false }
    }
  }
  inspect!(palindrome("abba"), content="true")
  inspect!(palindrome("中b中"), content="true")
  inspect!(palindrome("文bb中"), content="false")
}
// end array pattern 1

// start array pattern 2
const NO: Bytes = "no"
test {
  fn match_string(s: String) -> Bool {
    match s {
      [.."yes", ..] => true // equivalent to ['y', 'e', 's', ..]
    }
  }
  fn match_bytes(b: Bytes) -> Bool {
    match b {
      [..NO, ..] => false // equivalent to ['n', 'o', ..]
    }
  }
}
// end array pattern 2

enum Arith {
  Lit(Int)
  Add(Arith, Arith)
  Mul(Arith, Arith)
}

fn eval(expr : Arith) -> Int {
  // start pattern 3
  match expr {
    //! Add(e1, e2) | Lit(e1) => ...
    Lit(n) as a => ...
    Add(e1, e2) | Mul(e1, e2) => ...
    _ => ...
  }
  // end pattern 3
}

// start pattern 4
const Zero = 0

fn sign(x : Int) -> Int {
  match x {
    _..<Zero => -1
    Zero => 0
    1..<_ => 1
  }
}

fn classify_char(c : Char) -> String {
  match c {
    'a'..='z' => "lowercase"
    'A'..='Z' => "uppercase"
    '0'..='9' => "digit"
    _ => "other"
  }
}
// end pattern 4

fn map() -> Unit {
  let map = { "a": 1 }
  // start pattern 5
  match map {
    // matches if any only if "b" exists in `map`
    { "b": _, .. } => ...
    // matches if and only if "b" does not exist in `map` and "a" exists in `map`.
    // When matches, bind the value of "a" in `map` to `x`
    { "b"? : None, "a": x, .. } => ...
    // compiler reports missing case: { "b"? : None, "a"? : None }
  }
  // end pattern 5
}

fn json() -> Unit {
  let json = Null
  // start pattern 6
  match json {
    { "version": "1.0.0", "import": [..] as imports, .. } => ...
    { "version": Number(i), "import": Array(imports), ..} => ...
    _ => ...
  }
  // end pattern 6
}

// start simple pattern 1
const ONE = 1

fn match_int(x : Int) -> Unit {
  match x {
    0 => println("zero")
    ONE => println("one")
    value => println(value)
  }
}
// end simple pattern 1

// start simple pattern 2
struct Point3D {
  x : Int
  y : Int
  z : Int
}

fn match_point3D(p : Point3D) -> Unit {
  match p {
    { x: 0, .. } => println("on yz-plane")
    _ => println("not on yz-plane")
  }
}

enum Point[T] {
  Point2D(Int, Int, name~: String, payload~ : T)
}

fn match_point[T](p : Point[T]) -> Unit {
  match p {
    //! Point2D(0, 0) => println("2D origin")
    Point2D(0, 0, ..) => println("2D origin")
    Point2D(_) => println("2D point")
    _ => panic()
  }
}
// end simple pattern 2

// start guard condition 1
fn guard_cond(x : Int?) -> Int {
  fn f(x : Int) -> Array[Int] {
    [x, x + 42]
  }

  match x {
    Some(a) if f(a) is [0, b] => a + b
    Some(b) => b
    None => -1
  }
}

test {
  assert_eq!(guard_cond(None), -1)
  assert_eq!(guard_cond(Some(0)), 42)
  assert_eq!(guard_cond(Some(1)), 1)
}
// end guard condition 1

// start guard condition 2
fn guard_check(x: Int?) -> Unit {
  match x {
    Some(a) if a >= 0 => ()
    Some(a) if a < 0 => ()
    None => ()
  }
}
// end guard condition 2