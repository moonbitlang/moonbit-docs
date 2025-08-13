pub(open) trait Show {
  output(Self, &Logger) -> Unit
  to_string(Self) -> String
}