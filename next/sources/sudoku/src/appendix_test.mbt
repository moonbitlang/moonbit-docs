///|
let rows = "ABCDEFGHI"

///|
let cols = "123456789"

///|
typealias @immut/sorted_set.T[String] as Squares

///|
fn cross(x : String, y : String, pred : (String) -> Bool) -> Squares {
  let mut result = @immut/sorted_set.new()
  for chx in x {
    for chy in y {
      let res = chx.to_string() + chy.to_string()
      if pred(res) {
        result = result.add(res)
      }
    }
  }
  return result
}

///|
let squares : Squares = cross(rows, cols, fn { _ => true })

///|
fn unit_of(square : String) -> Squares {
  let row = square.charcode_at(0)
  let col = square.charcode_at(1)
  let rows = match row {
    'A'..='C' => "ABC"
    'D'..='F' => "DEF"
    'G'..='I' => "GHI"
    _ => abort("unitOf: invalid row \{row}")
  }
  let cols = match col {
    '1'..='3' => "123"
    '4'..='6' => "456"
    '7'..='9' => "789"
    _ => abort("unitOf: invalid col \{col}")
  }
  cross(rows, cols, fn { s => s != square })
}

///|
let units : Grid[Squares] = {
  let table = Grid::new(@immut/sorted_set.new())
  for square in squares {
    table[square] = unit_of(square)
  }
  table
}

///|
test {
  inspect(
    units["A1"].to_array(),
    content=
      #|["A2", "A3", "B1", "B2", "B3", "C1", "C2", "C3"]
    ,
  )
}

///|
fn is_peer(this : String, other : String) -> Bool {
  this != other &&
  (
    this.charcode_at(0) == other.charcode_at(0) ||
    this.charcode_at(1) == other.charcode_at(1) ||
    units[other].contains(this)
  )
}

///|
let peers : Grid[Squares] = {
  let table = Grid::new(@immut/sorted_set.new())
  for square in squares {
    table[square] = squares.filter(fn(sq) { is_peer(sq, square) })
  }
  table
}

///|
fn Grid::parse(s : String) -> Grid[@immut/sorted_set.T[Char]] {
  let digits = @immut/sorted_set.from_array(cols.to_array())
  let values = Grid::new(digits)
  let chars = s
    .iter()
    .filter(fn(ch) { ch is ('0'..='9') || ch == '.' })
    .collect()
  let pairs = squares.to_array().zip(chars)
  for p in pairs {
    let (square, digit) = p
    if digit is ('1'..='9') {
      if not(assign(values, square, digit)) {
        // println("parseGrid(): found contradiction")
        abort("parseGrid(): found contradiction")
      }
    }
  }
  return values
}

///|
fn Grid::format(self : Grid[@immut/sorted_set.T[Char]]) -> String {
  let rep = Array::make(81, "")
  let mut i = 0
  let mut maxWidth = 0
  while i < 81 {
    rep[i] = self.inner()[i].fold(init="", fn(acc, ch) { acc + ch.to_string() })
    maxWidth = @math.maximum(rep[i].length(), maxWidth)
    i = i + 1
  }
  let buf = StringBuilder::new(size_hint=1000)
  i = 0
  while i < 81 {
    buf.write_string(" ")
    buf.write_string(rep[i])
    buf.write_string(String::make(maxWidth - rep[i].length(), ' '))
    if (i + 1) % 27 == 0 && i + 1 != 81 {
      buf.write_string("\n")
      buf.write_string(String::make(maxWidth * 3 + 6, '-'))
      buf.write_string("+")
      buf.write_string(String::make(maxWidth * 3 + 6, '-'))
      buf.write_string("+")
      buf.write_string(String::make(maxWidth * 3 + 6, '-'))
      buf.write_string("\n")
    } else if (i + 1) % 9 == 0 {
      buf.write_string("\n")
    } else if (i + 1) % 3 == 0 {
      buf.write_string(" |")
    } else {
      buf.write_string(" ")
    }
    i = i + 1
  }
  buf.to_string()
}

///|
fn[T] Grid::contains(self : Grid[T], pred : (T) -> Bool) -> Bool {
  let mut result = false
  for i = 0; i < self.inner().length(); i = i + 1 {
    result = result || pred(self.inner()[i])
    if result {
      break
    }
  }
  return result
}
