pub(open) trait Stringer {
  stringify(Self) -> String = _
}

pub impl Stringer with stringify(_self) { "hey" }
