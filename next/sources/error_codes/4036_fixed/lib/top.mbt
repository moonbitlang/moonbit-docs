pub(all) struct R {
  x : Int
  priv __private : Int
}

pub fn R::new(x : Int) -> R {
  { x, __private: 42 }
}
