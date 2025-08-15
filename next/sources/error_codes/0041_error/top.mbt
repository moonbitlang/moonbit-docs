///|
fn f(map : Map[String, Int]) -> Bool {
  match map {
    // the pattern still matches 
    // if `map` contain elements other than "x" and "y"
    { "x": x, "y": y } => true
    _ => false
  }
}

///|
test {
  inspect(f({ "x": 1, "y": 2, "z": 3 }), content="true")
}
