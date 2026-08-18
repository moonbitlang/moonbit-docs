///|
/// start lexmatch strings
test "scan strings" {
  let text = "xx123yy"
  lexmatch text {
    (re"[0-9]+" as digits, before~, after~) => {
      inspect(before, content="xx")
      inspect(digits, content="123")
      inspect(after, content="yy")
    }
    _ => fail("")
  }

  lexmatch "letters123" with longest {
    (re"^[a-z]+" as word, after=rest) => {
      inspect(word, content="letters")
      inspect(rest, content="123")
    }
    _ => fail("")
  }
}
// end lexmatch strings

///|
/// start lexscan string scanner
priv enum Token {
  Word(StringView)
  Integer(StringView)
  Punctuation(Char)
  Eof
}

///|
fn next_string_token(input : @lexbuf.StringScanner) -> Token {
  lexscan input with longest {
    re"^[[:space:]]+" => next_string_token(input)
    re"^[[:alpha:]]+" as word => Word(word)
    re"^[[:digit:]]+" as digits => Integer(digits)
    re"^." as mark => Punctuation(mark)
    _ => Eof
  }
}

///|
test "scan an in-memory string with a maintained cursor" {
  let input = @lexbuf.StringScanner::{ data: "hello 123!"[:], cursor: 0 }
  guard next_string_token(input) is Word(word) else { fail("expected word") }
  assert_true(word == "hello")
  assert_eq(input.cursor, 5)
  guard next_string_token(input) is Integer(digits) else {
    fail("expected integer")
  }
  assert_true(digits == "123")
  assert_eq(input.cursor, 9)
  guard next_string_token(input) is Punctuation(mark) else {
    fail("expected punctuation")
  }
  assert_true(mark == '!')
  assert_eq(input.cursor, input.data.length())
  assert_true(next_string_token(input) is Eof)
  assert_eq(input.cursor, input.data.length())
}
// end lexscan string scanner

///|
test "StringScanner cursor is relative to its StringView" {
  let data = "xx🤣yzz".view(start_offset=2, end_offset=5)
  let input = @lexbuf.StringScanner::{ data, cursor: 0 }
  guard next_string_token(input) is Punctuation(mark) else {
    fail("expected punctuation")
  }
  assert_true(mark == '🤣')
  assert_eq(input.cursor, 2)
  guard next_string_token(input) is Word(word) else { fail("expected word") }
  assert_true(word == "y")
  assert_eq(input.cursor, data.length())
}

///|
/// start lexscan sync scanner
priv enum StreamToken {
  StreamWord(StringView)
  StreamInteger(StringView)
  StreamPunctuation(Char)
  StreamEof
}

///|
fn next_token(input : @lexbuf.Lexbuf) -> StreamToken {
  lexscan input with longest {
    re"^[[:space:]]+" => next_token(input)
    re"^[[:alpha:]]+" as word => StreamWord(word)
    re"^[[:digit:]]+" as digits => StreamInteger(digits)
    re"^." as mark => StreamPunctuation(mark)
    _ => StreamEof
  }
}

///|
test "scan a synchronous stream" {
  let chunks = ["hello ", "123!"][:].iter()
  let input = @lexbuf.Lexbuf::from_fn(() => chunks.next())
  guard next_token(input) is StreamWord(word) else { fail("expected word") }
  assert_true(word == "hello")
  guard next_token(input) is StreamInteger(digits) else {
    fail("expected integer")
  }
  assert_true(digits == "123")
  guard next_token(input) is StreamPunctuation(mark) else {
    fail("expected punctuation")
  }
  assert_true(mark == '!')
  assert_true(next_token(input) is StreamEof)
}
// end lexscan sync scanner

///|
/// start lexscan async scanner
/// Returns the next alphabetic token from an asynchronous lexbuf.
pub async fn next_word(input : @lexbuf.AsyncLexbuf) -> StringView? {
  lexscan input {
    re"^[[:alpha:]]+" as word => Some(word)
    _ => None
  }
}
// end lexscan async scanner

///|
async test "scan an asynchronous stream" {
  let mut sent = false
  let input = @lexbuf.AsyncLexbuf::from_fn(async fn() {
    @async.pause()
    if sent {
      None
    } else {
      sent = true
      Some("hello")
    }
  })
  guard next_word(input) is Some(word) else { fail("expected word") }
  assert_true(word == "hello")
}
