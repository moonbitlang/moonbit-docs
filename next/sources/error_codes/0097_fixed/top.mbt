///|
pub fn matches(input : String) -> Bool {
  re"^[01]*1[01]{20}$".execute(input) is Some(_)
}

///|
test {
  inspect(matches("100000000000000000000"), content="true")
  inspect(matches("000000000000000000000"), content="false")
  inspect(matches("1"), content="false")
}
