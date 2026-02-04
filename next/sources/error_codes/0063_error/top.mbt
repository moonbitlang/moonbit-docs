suberror DivError { DivError(String) }

fn div(x : Int, y : Int) -> Int raise DivError {
  if y == 0 {
    raise DivError("division by zero")
  }
  x / y
}

test {
  let res = match (try? div(6, 0)) {
    Ok(v) => v
    Err(_) => 0
  }
  inspect(res, content="0")
}
