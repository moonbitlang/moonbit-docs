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

// start alert
#alert(unsafe, "This function is unsafe.")
fn[A] alert_unsafe_get(arr : Array[A], index : Int) -> A {
  arr[index]
}
// end alert

// start alias
#alias(old_name, deprecated)
fn new_name() -> Unit {
  ()
}
// end alias

// start label_migration fill
#label_migration(x, fill=true)
#label_migration(y, fill=false)
fn label_migration_fill(x? : Int = 0, y? : Int = 1) -> Int {
  x + y
}
// end label_migration fill

// start label_migration allow_positional
#label_migration(x, allow_positional=true)
fn label_migration_allow_positional(x~ : Int) -> Int {
  x
}
// end label_migration allow_positional

// start label_migration alias
#label_migration(x, alias=xx)
#label_migration(x, alias=y, msg="warning")
fn label_migration_alias(x~ : Int) -> Int {
  x
}
// end label_migration alias

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

// start internal
#internal(unsafe, "This is an unsafe function")
fn[A] internal_unsafe_get(arr : Array[A], index : Int) -> A {
  arr[index]
}
// end internal

// start doc hidden
#doc(hidden)
pub fn hidden_helper() -> Unit {
  ()
}
// end doc hidden

// start warnings
#warnings("-unused_value")
fn warnings_example() -> Unit {
  let x = 42
}
// end warnings

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

// start inline default
#inline
fn add_one(x : Int) -> Int {
  x + 1
}
// end inline default

// start inline never
#inline(never)
fn keep_stack_frame(x : Int) -> Int {
  x + 1
}
// end inline never

// start external
#external
type AttrPtr
// end external

// start coverage skip
#coverage.skip
fn platform_specific_helper() -> Unit {
  ()
}
// end coverage skip

// start cfg
#cfg(true)
fn cfg_true() -> Unit {
  ()
}

#cfg(false)
fn cfg_false() -> Unit {
  ()
}

#cfg(target="wasm")
fn cfg_wasm() -> Unit {
  ()
}

#cfg(not(target="wasm"))
fn cfg_not_wasm() -> Unit {
  ()
}

#cfg(all(target="wasm", true))
fn cfg_all() -> Unit {
  ()
}

#cfg(any(target="wasm", target="native"))
fn cfg_any() -> Unit {
  ()
}
// end cfg

// start module
#module("math-utils")
pub extern "js" fn add_from_module(x : Int, y : Int) -> Int = "add"
// end module
