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
  if ary is [a, b, .. rest] && a == 1 && b == 2 && rest.length() == 2 {
    inspect("a = \{a}, b = \{b}", content="a = 1, b = 2")
  } else {
    fail("")
  }
  guard ary is [.., a, b] else { fail("") }
  inspect("a = \{a}, b = \{b}", content="a = 3, b = 4")
}
// end pattern 2

// start array pattern 1
test {
  fn palindrome(s : String) -> Bool {
    loop s.view() {
      [] | [_] => true
      [a, .. rest, b] => if a == b { continue rest } else { false }
    }
  }

  inspect(palindrome("abba"), content="true")
  inspect(palindrome("中b中"), content="true")
  inspect(palindrome("文bb中"), content="false")
}
// end array pattern 1

// start array pattern 2
const NO : Bytes = "no"

test {
  fn match_string(s : String) -> Bool {
    match s {
      [.. "yes", ..] => true // equivalent to ['y', 'e', 's', ..]
    }
  }

  fn match_bytes(b : Bytes) -> Bool {
    match b {
      [.. NO, ..] => false // equivalent to ['n', 'o', ..]
    }
  }
}
// end array pattern 2

// start bit pattern 1
test {
  let packet : Bytes = b"\xD2\x10\x7F"
  let header : BytesView = packet[0:2]
  let (flag, kind, version, length) = match header {
    [u1be(flag), u3be(kind), u4be(version), u8be(length)] => (flag, kind, version, length)
    _ => fail("bad header")
  }
  assert_eq(flag, 1)
  assert_eq(kind, 0b101)
  assert_eq(version, 0b0010)
  assert_eq(length, 16)
}
// end bit pattern 1

// start bit pattern 2
test {
  let data : Bytes = b"\xF1\xAA\xBB"
  let view : BytesView = data[0:]
  let tag = match view {
    [u4be(0b1111), u4be(tag), ..rest] => {
      assert_eq(rest, b"\xAA\xBB"[0:])
      tag
    }
    _ => fail("bad prefix")
  }
  assert_eq(tag, 0b0001)
}
// end bit pattern 2

// start bit pattern sources
test {
  let b : Bytes = b"\x80"
  guard b is [u1be(1), ..] else { fail("Bytes") }

  let a : Array[Byte] = [b'\x80']
  guard a is [u1be(1), ..] else { fail("Array[Byte]") }

  let f : FixedArray[Byte] = [b'\x80']
  guard f is [u1be(1), ..] else { fail("FixedArray[Byte]") }

  let r : ReadOnlyArray[Byte] = [b'\x80']
  guard r is [u1be(1), ..] else { fail("ReadOnlyArray[Byte]") }

  let v : ArrayView[Byte] = a[:]
  guard v is [u1be(1), ..] else { fail("ArrayView[Byte]") }

  let mv : MutArrayView[Byte] = a.mut_view()
  guard mv[:] is [u1be(1), ..] else { fail("MutArrayView[Byte]") }
}
// end bit pattern sources

// start bit pattern signed
test {
  let bytes = b"\x80"
  let u : UInt = match bytes[:] {
    [u1be(u), ..] => u
    _ => fail("u1be")
  }
  let i : Int = match bytes[:] {
    [i1be(i), ..] => i
    _ => fail("i1be")
  }
  assert_eq(u, 1U)
  assert_eq(i, -1)
}
// end bit pattern signed

// start bit pattern types
test {
  let bytes = b"\x80\x00\x00\x00\x00"
  let big : UInt64 = match bytes[:] {
    [u33be(x), ..] => x
    _ => fail("u33be")
  }
  assert_eq(big, 0x1_0000_0000UL)
}

test {
  let bytes = b"\x01\x02"
  let le : UInt = match bytes[:] {
    [u16le(x), ..] => x
    _ => fail("u16le")
  }
  assert_eq(le, 0x0201U)
}
// end bit pattern types

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
    ...
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
  let json = Json::null()
  // start pattern 6
  match json {
    { "version": "1.0.0", "import": [..] as imports, .. } => ...
    { "version": Number(i, ..), "import": Array(imports), .. } => ...
    ...
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
  Point2D(Int, Int, name~ : String, payload~ : T)
}

fn[T] match_point(p : Point[T]) -> Unit {
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
  assert_eq(guard_cond(None), -1)
  assert_eq(guard_cond(Some(0)), 42)
  assert_eq(guard_cond(Some(1)), 1)
}
// end guard condition 1

// start guard condition 2
fn guard_check(x : Int?) -> Unit {
  match x {
    Some(a) if a >= 0 => ()
    Some(a) if a < 0 => ()
    None => ()
  }
}
// end guard condition 2

// start lexmatch 1
test {
  let text = "xxabbbcyy"
  lexmatch text {
    (before, "a" ("b*" as b) "c", after) => {
      inspect(before, content="xx")
      inspect(b, content="bbb")
      inspect(after, content="yy")
    }
    _ => fail("")
  }

  if text lexmatch? ("a" ("b*" as b) "c") && b.length() > 0 {
    inspect(b, content="bbb")
  }

  let keyword = "iff"
  lexmatch keyword with longest {
    ("if|[a-z]*" as ident) => inspect(ident, content="iff")
    _ => fail("")
  }
}
// end lexmatch 1
