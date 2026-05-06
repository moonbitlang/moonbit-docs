fn match_text(s : String) -> Unit {
  ignore(s =~ ((re"a" | re"b") as either))
}
