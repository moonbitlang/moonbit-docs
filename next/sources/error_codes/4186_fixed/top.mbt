///|
pub fn match_text(text : String) -> Unit {
  lexscan text with longest {
    re"^abc$" => if text.length() > 0 { () }
    _ => ()
  }
}
