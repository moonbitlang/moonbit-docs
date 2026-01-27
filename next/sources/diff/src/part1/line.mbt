///|
/// start line definition
///
struct Line {
  number : Int // Line number
  text : String // Does not include newline
} derive(Show, ToJson)

///|
fn Line::new(number : Int, text : String) -> Line {
  Line::{ number, text }
}
// end line definition

///|
/// start lines definition
///
fn lines(str : String) -> Array[Line] {
  let lines = Array::new(capacity=50)
  let mut line_number = 0
  for line in str.split("\n") {
    line_number = line_number + 1
    lines.push(Line::new(line_number, line.to_string()))
  } else {
    return lines
  }
}
// end lines definition

///|
test "lines" {
  json_inspect(lines(""), content=[{ "number": 1, "text": "" }])
  json_inspect(lines("\n"), content=[
    { "number": 1, "text": "" },
    { "number": 2, "text": "" },
  ])
  json_inspect(lines("aaa"), content=[{ "number": 1, "text": "aaa" }])
  json_inspect(lines("aaa\nbbb"), content=[
    { "number": 1, "text": "aaa" },
    { "number": 2, "text": "bbb" },
  ])
}
