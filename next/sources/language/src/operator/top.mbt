/// start operator 1
struct T {
  x : Int
}

impl Add for T with add(self : T, other : T) -> T {
  { x: self.x + other.x }
}

test {
  let a = { x: 0 }
  let b = { x: 2 }
  assert_eq((a + b).x, 2)
}
// end operator 1

/// start operator 2
struct Coord {
  mut x : Int
  mut y : Int
}

#alias("_[_]")
fn Coord::get(coord : Self, key : String) -> Int {
  match key {
    "x" => coord.x
    "y" => coord.y
  }
}

#alias("_[_]=_")
fn Coord::set(coord : Self, key : String, val : Int) -> Unit {
  match key {
    "x" => coord.x = val
    "y" => coord.y = val
  }
}
// end operator 2

test "operator 3" (t : @test.Test) {
  let println = fn(show) { t.writeln(show) }
  // start operator 3
  let c = { x: 1, y: 2 }
  println("{x: \{c.x}, y: \{c.y}}")
  println(c["y"])
  c["x"] = 23
  println("{x: \{c.x}, y: \{c.y}}")
  println(c["x"])
  // end operator 3
  t.snapshot(filename="operator_3")
}

fn add(i : Int, j : Int) -> Int {
  i + j
}

fn pipe() -> Unit {
  // start operator 4
  5 |> ignore // <=> ignore(5)
  [] |> Array::push(5) // <=> Array::push([], 5)
  1
  |> add(5) // <=> add(1, 5)
  |> x => { x + 1 }
  |> ignore // <=> ignore(add(1, 5))
  // end operator 4
}

fn text(content : String) -> String {
  "text(" + content + ")"
}

fn div(children : Array[String]) -> String {
  "div(" + children.join(", ") + ")"
}

fn section(title : String, body : () -> Array[String]) -> String {
  title + ": " + (div <| body())
}

test {
  // start operator 4 reverse
  let page = div <| [
      text <| "hello",
      section("toolbar") <| fn() { [text <| "save", text <| "cancel"] },
    ]
  inspect(
    page,
    content="div(text(hello), toolbar: div(text(save), text(cancel)))",
  )
  // end operator 4 reverse
}

trait Ignore {
  f(Self) -> Unit
}

impl Ignore for Unit with f(u) {
  u
}

fn cascade() -> Unit {
  // start operator 5
  let arr = []..append([1])
  // end operator 5
  // start operator 6
  let builder = StringBuilder::new()
  builder.write_char('a')
  builder.write_char('a')
  builder.write_object(1001)
  builder.write_string("abcdef")
  let result = builder.to_string()
  // end operator 6

  // start operator 7
  let result = StringBuilder::new()
    ..write_char('a')
    ..write_char('a')
    ..write_object(1001)
    ..write_string("abcdef")
    .to_string()
  // end operator 7

}

impl BitAnd for T with land(self : T, other : T) -> T {
  { x: self.x & other.x }
}

impl BitOr for T with lor(self : T, other : T) -> T {
  { x: self.x | other.x }
}

impl BitXOr for T with lxor(self : T, other : T) -> T {
  { x: self.x ^ other.x }
}

impl Shl for T with shl(self : T, other : Int) -> T {
  { x: self.x << other }
}

impl Shr for T with shr(self : T, other : Int) -> T {
  { x: self.x >> other }
}

test {
  let a = { x: 0b1010 }
  let b = { x: 0b1100 }
  assert_eq((a & b).x, 0b1000)
  assert_eq((a | b).x, 0b1110)
  assert_eq((a ^ b).x, 0b0110)
  assert_eq((a << 2).x, 0b101000)
  assert_eq((b >> 2).x, 0b11)
}

/// start view 1
test {
  let xs = [0, 1, 2, 3, 4, 5]
  let s1 : ArrayView[Int] = xs[2:]
  @test.assert_eq(s1.to_owned(), [2, 3, 4, 5])
  @test.assert_eq(xs[:4].to_owned(), [0, 1, 2, 3])
  @test.assert_eq(xs[2:5].to_owned(), [2, 3, 4])
  @test.assert_eq(xs[:].to_owned(), [0, 1, 2, 3, 4, 5])
  let mv : MutArrayView[Int] = xs.mut_view(start=1, end=3)
  mv[0] = 99
  inspect(xs[1], content="99")
}
// end view 1

/// start view 2
struct DataView(String)

struct Data {}

#alias("_[_:_]")
fn Data::as_view(_self : Data, start? : Int = 0, end? : Int) -> DataView {
  "[\{start}, \{end.unwrap_or(100)})"
}

test {
  let data = Data::{  }
  inspect(data[:].0, content="[0, 100)")
  inspect(data[2:].0, content="[2, 100)")
  inspect(data[:5].0, content="[0, 5)")
  inspect(data[2:5].0, content="[2, 5)")
}
// end view 2

/// start spread 1
test {
  let a1 : Array[Int] = [1, 2, 3]
  let a2 : FixedArray[Int] = [4, 5, 6]
  let a3 : @list.List[Int] = @list.from_array([7, 8, 9])
  let a : Array[Int] = [..a1, ..a2, ..a3, 10]
  debug_inspect(a, content="[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]")
}
// end spread 1

/// start spread 2
test {
  let s1 : String = "Hello"
  let s2 : StringView = "World".view()
  let s3 : Array[Char] = [..s1, ' ', ..s2, '!']
  let s : String = [..s1, ' ', ..s2, '!', ..s3]
  inspect(s, content="Hello World!Hello World!")
}
// end spread 2

/// start spread 3
test {
  let b1 : Bytes = b"hello"
  let b2 : BytesView = b1[1:4]
  let b : Bytes = [..b1, ..b2, 10]
  inspect(
    b,
    content=(
      #|b"helloell\x0a"
    ),
  )
}
// end spread 3
