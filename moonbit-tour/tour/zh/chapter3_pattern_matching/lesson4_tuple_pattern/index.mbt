fn logical_and(x : Bool, y : Bool) -> Bool {
  match (x, y) {
    (true, true) => true
    (false, _) => false
    (_, false) => false
  }
}

fn logical_or(x : Bool, y : Bool) -> Bool {
  match (x, y) {
    (true, _) => true
    (_, true) => true
    _ => false
  }
}

fn main {
  println("true and false: \{logical_and(true, false)}")
  println("true or false: \{logical_or(true, false)}")
}
