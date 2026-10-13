impl @a.T with f(self : Self) -> Int32 {
  //           ^
  // Error: Cannot provide default implementation for trait @a.T from package a
  ignore(self)
  0
}
