fn score_to_grade(score : Int) -> String {
  match score {
    0..<60 => "F"
    60..<70 => "D"
    70..<80 => "C"
    80..<90 => "B"
    90..=100 => "A"
    _ => "Invalid score"
  }
}

fn classify_char(c : Char) -> String {
  match c {
    'A'..='Z' => "UpperCase"
    'a'..='z' => "LowerCase"
    '0'..='9' => "Digit"
    _ => "Special"
  }
}

fn is_scalar_value(codepoint : Int) -> Bool {
  match codepoint {
    0x0000..=0xD7FF | 0xE000..=0x10FFFF => true
    _ => false
  }
}

fn main {
  println(score_to_grade(50))
  println(score_to_grade(85))
  println(score_to_grade(95))
  println(classify_char('A'))
  println(classify_char('1'))
  println(classify_char('!'))
  println(is_scalar_value(0xD500))
}
