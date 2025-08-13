pub type WrapA @a.A

fn f(self : WrapA) -> Int {
  ignore(self._) // Use `._` to access the wrapped value if @a.A is public
  0
}