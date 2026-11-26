///|
test "scan bytes with a maintained cursor" {
  let scanner = @lexbuf.BytesScanner(b"abc\xff")
  lexscan scanner {
    reb"^[a-z]+" as word => {
      assert_true(word == b"abc")
      assert_eq(scanner.cursor, 3)
    }
    _ => fail("expected a word")
  }
  lexscan scanner {
    reb"^." as byte => {
      assert_eq(byte, b'\xff')
      assert_eq(scanner.cursor, 4)
    }
    _ => fail("expected a byte")
  }
  lexscan scanner {
    reb"^." => fail("expected end of input")
    _ => assert_eq(scanner.cursor, 4)
  }
}
