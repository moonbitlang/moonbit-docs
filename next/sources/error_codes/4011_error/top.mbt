pub(open) trait Stringer {
  stringify(Self) -> String = _
}

impl[T] Stringer with stringify(_self) { "hey" }
