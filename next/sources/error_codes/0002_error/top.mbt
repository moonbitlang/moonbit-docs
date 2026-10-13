///|
let p : Int32 = {
  side_effect.val = 42
  42
}

///|
let side_effect : Ref[Int32] = { val: 0 }

///|
test {
  let x = 42

}
