///|
fn f(map : Map[String, Int]) -> Bool {
  match map {
    { "x": x, "y": y, .. } if map.size() == 2 => true
    _ => false
  }
}

///|
test {
  inspect(f({ "x": 1, "y": 2, "z": 3 }), content="false")
}
