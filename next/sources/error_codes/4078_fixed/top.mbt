///|
pub type T

///|
pub impl Hash for T with hash_combine(self : T, hasher : Hasher) -> Unit {
  ignore(self)
  ignore(hasher)
}

///|
pub extend T with Hash::{hash, hash_combine}
