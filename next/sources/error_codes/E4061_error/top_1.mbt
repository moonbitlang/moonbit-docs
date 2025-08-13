impl @a.B for @a.A with to_int(self : @a.A) -> Int {
  //                    ^~~~~~
  // Error: Cannot define method to_int of trait @a.B from package a for type @a.A from package a
  self._
}