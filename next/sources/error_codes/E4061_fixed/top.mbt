type WrapA @a.A

impl @a.B for WrapA with to_int(self : WrapA) -> Int {
  ...
}