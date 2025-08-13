fn f(map : Map[String, Int]) -> Unit {
  match map {
    // the pattern still matches if `map` contain elements other than "x" and "y"
    { "x": x, "y": y } => println(x + y)
    _ => ()
  }
}

test {
 f({ "x": 1, "y": 2, "z": 3 })
}
