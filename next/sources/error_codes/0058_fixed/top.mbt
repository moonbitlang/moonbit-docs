///|
test {
  let text = "xxabcyy"
  if text =~ (re"a" + (re"b" as middle) + re"c", before~, after~) {
    inspect(before, content="xx")
    inspect(middle, content="b")
    inspect(after, content="yy")
  } else {
    fail("")
  }
}
