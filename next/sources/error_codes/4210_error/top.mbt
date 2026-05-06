fn match_text(s : String) -> Unit {
  ignore(s =~ ((re"a" as left) | re"b"))
}
