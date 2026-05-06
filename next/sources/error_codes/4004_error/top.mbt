trait Stringer {
  stringify[T : Show](Self, T) -> String
}
