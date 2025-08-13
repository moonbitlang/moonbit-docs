pub(open) trait Stringer {
  stringify(Self) -> String
}

impl Stringer with stringify(_self) { "hey" }