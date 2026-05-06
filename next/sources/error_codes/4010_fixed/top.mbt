pub(open) trait Stringer {
  stringify(Self) -> String = _
}

impl Stringer with stringify(_self) { "hey" }