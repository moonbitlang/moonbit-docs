typealias FuncAlias = (Int) -> Unit

pub fn FuncAlias::call(self : FuncAlias) -> Unit {
  //   ^~~~~~~~~
  // Error: The type alias FuncAlias is a function type, not a type constructor.
  self(0)
}