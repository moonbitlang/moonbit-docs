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
/// start lexscan sync scanner
priv enum Token {
  Word(StringView)
  Integer(StringView)
  Punctuation(Char)
  Eof
}

///|
fn next_token(input : @lexbuf.Lexbuf) -> Token {
  lexscan input with longest {
    re"^[[:space:]]+" => next_token(input)
    re"^[[:alpha:]]+" as word => Word(word)
    re"^[[:digit:]]+" as digits => Integer(digits)
    re"^." as mark => Punctuation(mark)
    _ => Eof
  }
}

///|
test "scan a synchronous stream" {
  let input = @lexbuf.Lexbuf::from_string("hello 123!")
  guard next_token(input) is Word(word) else { fail("expected word") }
  assert_true(word == "hello")
  guard next_token(input) is Integer(digits) else { fail("expected integer") }
  assert_true(digits == "123")
  guard next_token(input) is Punctuation(mark) else {
    fail("expected punctuation")
  }
  assert_true(mark == '!')
  assert_true(next_token(input) is Eof)
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
