///|
struct Line {
  number : Int // Line number
  text : String // Does not include newline
} derive(Show)

///|
fn Line::new(number : Int, text : String) -> Line {
  Line::{ number, text }
}

///|
fn lines(str : String) -> Array[Line] {
  let lines = Array::new(capacity=50)
  let mut line_number = 0
  for line in str.split("\n") {
    line_number = line_number + 1
    lines.push(Line::new(line_number, line))
  } else {
    return lines
  }
}

test "lines" {
  inspect!(lines(""), content="[]")
  inspect!(
    lines("\n"),
    content=
      #|[{number: 1, text: ""}]
    ,
  )
  inspect!(
    lines("aaa"),
    content=
      #|[{number: 1, text: "aaa"}]
    ,
  )
  inspect!(
    lines("aaa\nbbb"),
    content=
      #|[{number: 1, text: "aaa"}, {number: 2, text: "bbb"}]
    ,
  )
}
