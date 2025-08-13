type A Int

impl @a.Sealed for A with to_int(self : A) -> Int { // Error: Cannot implement trait '@a.Sealed' because it is readonly.
  self._
}