test {
  let s = StringBuilder()
    ..write_string("a")
    .to_string()
  inspect(s, content="a")
}

