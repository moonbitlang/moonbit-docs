///|
priv struct WordScanner {
  input : StringView
  mut cursor : Int32
}

///|
impl @lexbuf.Scannable for WordScanner with fn scan_input(self) {
  self.input
}

///|
impl @lexbuf.Scannable for WordScanner with fn scan_cursor(self) {
  self.cursor
}

///|
impl @lexbuf.Scannable for WordScanner with fn set_scan_cursor(self, cursor) {
  self.cursor = cursor
}

///|
test "scan with a cursor stored in a custom type" {
  let scanner = WordScanner::{ input: "hello!", cursor: 0, }
  lexscan scanner {
    re"^[a-z]+" as word => {
      inspect(word, content="hello")
      assert_eq(scanner.cursor, 5)
    }
    _ => fail("expected a word")
  }
  lexscan scanner {
    re"^[a-z]+" => fail("expected punctuation")
    _ => assert_eq(scanner.cursor, 5)
  }
}
