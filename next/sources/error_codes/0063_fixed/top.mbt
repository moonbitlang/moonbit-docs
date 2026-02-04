suberror DivError { DivError(String) }

fn div(x : Int, y : Int) -> Int raise DivError {
  if y == 0 {
    raise DivError("division by zero")
  }
  x / y
}

test {
  try div(6, 0) catch {
    DivError(_) => inspect(0, content="0")
  } noraise {
    v => inspect(v, content="0")
  }
}
