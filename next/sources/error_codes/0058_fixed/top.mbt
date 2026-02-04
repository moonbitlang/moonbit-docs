test {
  let text = "xxabcyy"
  lexmatch text {
    (before, "a" "b" "c", after) => {
      inspect(before, content="xx")
      inspect(after, content="yy")
    }
    _ => fail("")
  }
}
