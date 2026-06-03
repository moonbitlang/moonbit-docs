///|
test {
  let text = "xxabcyy"
  if text =~ (re"a(?:b)c", before~, after~) {
    inspect(before, content="xx")
    inspect(after, content="yy")
  } else {
    fail("")
  }
}
