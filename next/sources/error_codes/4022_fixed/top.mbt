///|
const WORD = re"[A-Za-z]+"

///|
fn has_word(input : String) -> Bool {
  input =~ WORD
}

///|
test {
  inspect(has_word("MoonBit"), content="true")
}
