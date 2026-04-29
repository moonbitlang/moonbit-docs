// start deprecated
#deprecated
pub fn foo() -> Unit {
  ...
}

#deprecated("Use Bar2 instead")
pub(all) enum Bar {
  Ctor1
  Ctor2
}
// end deprecated

// start visibility
// in @util package
#visibility(change_to="readonly", "Point will be readonly in the future.")
pub(all) struct Point {
  x : Int
  y : Int
}

#visibility(change_to="abstract", "Use new_text and new_binary instead.")
pub(all) enum Resource {
  Text(String)
  Binary(Bytes)
}

pub fn new_text(str : String) -> Resource {
  ...
}

pub fn new_binary(bytes : Bytes) -> Resource {
  ...
}

// in another package
fn main {
  let p = Point::{ x: 1, y: 2 } // warning 
  let { x, y } = p // ok
  println(p.x) // ok
  match Resource::Text("") { // warning
    Text(s) => ... // waning
    Binary(b) => ... // warning
  }
}

// end visibility

// start must_implement_one any
#must_implement_one
pub(open) trait RequireAnyMethod {
  f(Self) -> Unit = _
  g(Self) -> Unit = _
}

impl RequireAnyMethod with f(_) {}

impl RequireAnyMethod with g(_) {}

type AnyImpl

impl RequireAnyMethod for AnyImpl with f(_) {}
// end must_implement_one any

// start must_implement_one selected
#must_implement_one(f, g)
pub(open) trait RequireSelectedMethod {
  f(Self) -> Unit = _
  g(Self) -> Unit = _
  h(Self) -> Unit = _
}

impl RequireSelectedMethod with f(_) {}

impl RequireSelectedMethod with g(_) {}

impl RequireSelectedMethod with h(_) {}

type SelectedImpl

impl RequireSelectedMethod for SelectedImpl with g(_) {}
// end must_implement_one selected
