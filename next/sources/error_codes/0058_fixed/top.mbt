///|
test {
  let text = "xxabcyy"
  if text =~ (re"abc", before~, after~) {
    inspect(before, content="xx")
    inspect(after, content="yy")
  } else {
    fail("")
  }
}
