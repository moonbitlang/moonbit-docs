test {
  let s = StringBuilder::new()
    ..write_string("a")
    .to_string()
  inspect(s, content="a")
}

