///|
test "parse config for stdout" {
  let config = parse_config(["https://example.com/feed.xml"])
  assert_eq(config.url, "https://example.com/feed.xml")
  assert_eq(config.output, None)
}

///|
test "parse config for file output" {
  let config = parse_config(["https://example.com/feed.xml", "-o", "feed.xml"])
  assert_eq(config.url, "https://example.com/feed.xml")
  guard config.output is Some(path) else { fail("expected an output path") }
  assert_eq(path, "feed.xml")
}
