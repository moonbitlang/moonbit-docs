impl Number for A with to_float(self : A) -> Float {
  self.inner().to_float()
}