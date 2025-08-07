///|
let p : Int = {
  side_effect.val = 42
  42
}

///|
let side_effect : Ref[Int] = { val: 0 }

///|
test {
  let x = 42

}
