func testCharacterFunctions(char) {
  match @lib.is_alpha(char) {
    true => println("is alpha")
    false => println("is not alpha")
  }
  match @lib.is_numeric(char) {
    true => println("is numeric")
    false => println("is not numeric")
  }
  match @lib.is_alphanumeric(char) {
    true => println("is alphanumeric")
    false => println("is not alphanumeric")
  }
  println(@lib.to_lower(char))
  println(@lib.to_upper(char))
  match @lib.is_whitespace(char) {
    true => println("True")
    false => println("False")
  }
  match @lib.next(char) {
    Some(v) => println(v)
    None => ()
  }
  match @lib.prev(char) {
    Some(v) => println(v)
    None => ()
  }
}

func testCharacterFunctionsArray(characters) {
  for char in characters {
    println("Testing character: " + char)
    testCharacterFunctions(char)
  }
}

// Test with an array of characters
testCharacterFunctionsArray(['a', '3', '1', 'b', 'H', 'c', ' ', 'Z', 'A'])
