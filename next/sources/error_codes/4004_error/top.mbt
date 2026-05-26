trait Stringer {
  fn[T : Show] stringify(Self, T) -> String
}
