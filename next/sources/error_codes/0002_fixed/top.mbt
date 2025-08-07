// make public

///|
pub let p = 42
// end make public

// side effect solution

///|
let side_effect : Ref[Int] = { val: 0 }

///|
fn init {
  side_effect.val = 42
}
// end side effect solution

// ignore unused

///|
let p_unused : Int = 42

///|
test {
  ignore(p_unused)
}

///|
fn main {
  let x = 42
  ignore(x)
}
// end ignore unused
