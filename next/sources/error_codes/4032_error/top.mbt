pub fn make(x : Missing) -> Unit {
  //          ^~~~~~~
  // Error: The type Missing is undefined.
  ignore(x)
}
