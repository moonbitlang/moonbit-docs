test {
  ignore(
    StringBuilder::new()
      ..write_string("a")
      ..to_string(),
  )
}

