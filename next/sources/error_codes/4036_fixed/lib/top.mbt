pub(all) struct R {
  x : Int32
  priv __private : Int32
}

pub fn R::new(x : Int32) -> R {
  { x, __private: 42 }
}
